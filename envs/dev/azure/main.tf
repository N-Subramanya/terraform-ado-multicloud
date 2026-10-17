terraform {
  required_version = ">= 1.10"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}

# Auth comes from the environment: ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID and ARM_OIDC_TOKEN,
# set by the pipeline from the workload identity federation service connection (or `az login` locally).
provider "azurerm" {
  features {}
  storage_use_azuread = true
}

module "azure" {
  source = "../../../modules/azure"

  environment                     = "dev"
  location                        = var.location
  aks_sku_tier                    = var.aks_sku_tier
  node_vm_size                    = var.node_vm_size
  node_min_count                  = var.node_min_count
  node_max_count                  = var.node_max_count
  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  admin_group_object_ids          = var.admin_group_object_ids
  log_retention_days              = var.log_retention_days
}
