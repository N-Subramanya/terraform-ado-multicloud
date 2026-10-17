# Azure DevOps Setup

End-to-end setup to run `azure-pipelines.yml` against your own Azure subscription and AWS account.
Total time: about 30–45 minutes. Replace every `<placeholder>`.

---

## 1. Remote state (one time)

**Azure:** a Storage account with Entra ID auth only (shared keys disabled), versioning and soft delete:

```bash
az login
./scripts/bootstrap-azure-state.sh rg-tfstate <sttfstateunique> eastus tfstate
```

**AWS:** an S3 bucket that is versioned, KMS-encrypted and private. Locking uses S3 native lock files, so no DynamoDB table is needed:

```bash
aws configure   # or aws sso login
./scripts/bootstrap-aws-state.sh <my-tfstate-bucket> us-east-1
```

## 2. Azure service connection (workload identity federation)

**Project settings → Service connections → New → Azure Resource Manager**

| Field | Value |
|---|---|
| Identity type | App registration (automatic) |
| Credential | **Workload identity federation** (no secret to rotate) |
| Scope | Subscription |
| Name | `sc-azure-wif` |

Permissions for the service connection's identity:

| Role | Scope | Why |
|---|---|---|
| `Contributor` | Subscription | Create the resource groups, VNet, AKS and Log Analytics |
| `Storage Blob Data Contributor` | State storage account | Read/write state with Entra ID (printed by the bootstrap script) |

## 3. AWS service connection (OIDC role)

1. Install the **AWS Toolkit for Azure DevOps** extension from the Visual Studio Marketplace.
2. In IAM, create an **OIDC identity provider** for Azure DevOps:
   - Provider URL: `https://vstoken.dev.azure.com/<azure-devops-organization-id>`
   - Audience: `api://AzureADTokenExchange`
3. Create an IAM role trusted by that provider, with the subject condition
   `sc://<organization>/<project>/sc-aws`, and attach permissions for VPC, EC2, ELB, Auto Scaling, IAM roles, KMS, CloudWatch Logs, ACM, Route 53, plus the state bucket.
4. **Project settings → Service connections → New → AWS**: name `sc-aws`, tick **Use OIDC**, and set the role ARN.

> Using access keys also works (paste them into `sc-aws`), but OIDC means there are no long-lived keys to leak or rotate.

## 4. Variable group

**Pipelines → Library → + Variable group** → `vg-terraform-common` (no secrets needed):

| Variable | Example | Used by |
|---|---|---|
| `TF_STATE_RG` | `rg-tfstate` | Azure backend |
| `TF_STATE_STORAGE_ACCOUNT` | `sttfstateunique` | Azure backend |
| `TF_STATE_CONTAINER` | `tfstate` | Azure backend |
| `TF_STATE_BUCKET` | `my-tfstate-bucket` | AWS backend |
| `TF_STATE_REGION` | `us-east-1` | AWS backend |
| `AWS_REGION` | `us-east-1` | AWS task region |

Allow the pipeline to use the group: **Pipeline permissions → +**.

## 5. Environments and approvals

**Pipelines → Environments → New environment**:

| Environment | Checks |
|---|---|
| `dev` | none, applies straight after the plan |
| `prod` | **Approvals**: one or more reviewers, who read the plan summary first |

## 6. Create and run the pipeline

1. **Pipelines → New pipeline → GitHub** → select this repo. ADO picks up `azure-pipelines.yml`.
2. Authorize the service connections, variable group and environments on the first run.
3. Click **Run pipeline** and choose the parameters:

| Goal | cloud | environment | action |
|---|---|---|---|
| See what would change | `azure` / `aws` / `both` | `dev` | `plan` |
| Deploy dev on both clouds | `both` | `dev` | `apply` |
| Deploy prod Azure, after approval | `azure` | `prod` | `apply` |
| Tear down dev AWS | `aws` | `dev` | `destroy` |

Each Plan job uploads a **plan summary** to the run's Summary tab, plus the full plan as the `tfplan_<cloud>` artifact. The Apply stage applies **exactly that saved plan**.

## 7. Golden AMI for AWS prod

`envs/prod/aws` uses `use_golden_ami = true`, so build the image once before applying prod:

```bash
cd packer
packer init .
packer build -var "region=us-east-1" .
```

## 8. Run locally (optional)

```bash
az login                    # Azure
aws sso login               # or aws configure
export TF_STATE_RG=... TF_STATE_STORAGE_ACCOUNT=... TF_STATE_CONTAINER=...
export TF_STATE_BUCKET=... TF_STATE_REGION=us-east-1
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

./scripts/tf.sh azure dev plan
./scripts/tf.sh azure dev apply
```

## 💰 Cost notes

| Stack | Main cost drivers | Rough idea |
|---|---|---|
| Azure dev | 1× `Standard_B2s` node, Free AKS tier, Log Analytics ingestion | low tens of USD / month |
| AWS dev | NAT gateway, ALB, 1× `t3.micro` | ~USD 50–60 / month (mostly NAT + ALB) |
| prod (both) | Standard AKS tier, bigger nodes, 2+ instances | much higher, so use it for demos only |

Run `action = destroy` when you're done. Set `enable_nat_gateway = false` for the cheapest AWS demo, though instances then can't reach package mirrors, so use the golden AMI.

## 🔧 Troubleshooting

| Symptom | Fix |
|---|---|
| `AuthorizationFailed` on the Azure backend | Assign `Storage Blob Data Contributor` on the state account to the service connection identity |
| `No valid credential sources` (AWS) | Check that the `sc-aws` OIDC role trust subject matches `sc://<org>/<project>/sc-aws` |
| Plan fails: `no matching EC2 AMI` (prod) | Build the golden AMI first (step 7) or set `use_golden_ami = false` |
| `Error acquiring the state lock` | Another run holds the lock; wait, or `terraform force-unlock <id>` |
| Apply stage is skipped | It only runs when `action` is `apply`/`destroy` and never for pull requests |
