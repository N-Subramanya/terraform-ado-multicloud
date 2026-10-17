#!/usr/bin/env bash
# Runs Terraform for one cloud/environment with the right remote-state backend.
#
#   scripts/tf.sh <azure|aws> <dev|prod> <plan|plan-destroy|apply>
#
# Backend settings come from environment variables (ADO variable group vg-terraform-common):
#   azure: TF_STATE_RG, TF_STATE_STORAGE_ACCOUNT, TF_STATE_CONTAINER
#   aws:   TF_STATE_BUCKET, TF_STATE_REGION
# Cloud credentials come from the calling task (AzureCLI@2 / AWSShellScript@1) or your local login.
set -euo pipefail

cloud="${1:?cloud (azure|aws) required}"
env="${2:?environment (dev|prod) required}"
cmd="${3:?command (plan|plan-destroy|apply) required}"

dir="envs/${env}/${cloud}"
[[ -d "$dir" ]] || { echo "No such stack: $dir" >&2; exit 1; }

case "$cloud" in
  azure)
    backend=(
      -backend-config="resource_group_name=${TF_STATE_RG:?}"
      -backend-config="storage_account_name=${TF_STATE_STORAGE_ACCOUNT:?}"
      -backend-config="container_name=${TF_STATE_CONTAINER:?}"
    )
    ;;
  aws)
    backend=(
      -backend-config="bucket=${TF_STATE_BUCKET:?}"
      -backend-config="region=${TF_STATE_REGION:?}"
    )
    ;;
  *)
    echo "Unknown cloud: $cloud" >&2
    exit 1
    ;;
esac

if [[ "$cmd" == "apply" && ! -f "$dir/tfplan" ]]; then
  echo "No saved plan at $dir/tfplan (run the Plan stage first)" >&2
  exit 1
fi

echo "==> terraform init ($cloud/$env)"
terraform -chdir="$dir" init -input=false "${backend[@]}"

case "$cmd" in
  plan | plan-destroy)
    extra=()
    [[ "$cmd" == "plan-destroy" ]] && extra=(-destroy)
    echo "==> terraform plan${extra[*]:+ ${extra[*]}} ($cloud/$env)"
    terraform -chdir="$dir" plan -input=false -lock-timeout=5m "${extra[@]}" -out=tfplan
    terraform -chdir="$dir" show -no-color tfplan > "$dir/tfplan.txt"
    ;;
  apply)
    echo "==> terraform apply saved plan ($cloud/$env)"
    terraform -chdir="$dir" apply -input=false -lock-timeout=5m tfplan
    terraform -chdir="$dir" output
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    exit 1
    ;;
esac
