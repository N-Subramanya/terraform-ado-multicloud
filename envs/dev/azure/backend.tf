# Remote state in Azure Storage, authenticated with Entra ID (no storage account keys).
# resource_group_name, storage_account_name and container_name are passed at init time
# (see scripts/tf.sh), so no environment-specific names are hard-coded here.
terraform {
  backend "azurerm" {
    key              = "dev/azure.tfstate"
    use_azuread_auth = true
  }
}
