#!/usr/bin/env bash
# One-time setup: Azure Storage for Terraform state (Entra ID auth only, no shared keys).
#   scripts/bootstrap-azure-state.sh <resource-group> <storage-account> [location] [container]
set -euo pipefail

rg="${1:?resource group required}"
sa="${2:?storage account name required (3-24 lowercase letters/digits)}"
location="${3:-eastus}"
container="${4:-tfstate}"

az group create --name "$rg" --location "$location" --output none

az storage account create \
  --name "$sa" --resource-group "$rg" --location "$location" \
  --sku Standard_ZRS --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --allow-shared-key-access false \
  --output none

az storage account blob-service-properties update \
  --account-name "$sa" --resource-group "$rg" \
  --enable-versioning true \
  --enable-delete-retention true --delete-retention-days 30 \
  --output none

az storage container-rm create --storage-account "$sa" --resource-group "$rg" --name "$container" --output none

scope="$(az storage account show --name "$sa" --resource-group "$rg" --query id --output tsv)"
echo "State storage ready: $sa/$container"
echo "Grant the pipeline identity access to state:"
echo "  az role assignment create --assignee <service-connection-app-id> --role 'Storage Blob Data Contributor' --scope $scope"
