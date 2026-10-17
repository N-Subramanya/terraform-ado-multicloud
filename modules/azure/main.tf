locals {
  name = "${var.project}-${var.environment}"
  tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  })
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

# ---------------- Network ----------------

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]
  tags                = local.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 4, 0)] # /20 for nodes
}

resource "azurerm_network_security_group" "aks" {
  name                = "nsg-aks-${local.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# ---------------- Observability ----------------

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

# ---------------- AKS ----------------

resource "azurerm_kubernetes_cluster" "this" {
  #checkov:skip=CKV_AZURE_6:Authorized IP ranges are a variable, set per environment in tfvars
  #checkov:skip=CKV_AZURE_115:Public API server (Entra ID auth, local accounts disabled); private cluster needs private agents/VPN
  #checkov:skip=CKV_AZURE_117:Platform-managed disk encryption; customer-managed keys need Key Vault + disk encryption set
  #checkov:skip=CKV_AZURE_170:SKU tier is a variable: Free in dev, Standard (SLA) in prod
  #checkov:skip=CKV_AZURE_226:Ephemeral OS disks need a VM size with a large enough cache (not B-series in dev)
  #checkov:skip=CKV_AZURE_227:Encryption at host requires the EncryptionAtHost subscription feature
  #checkov:skip=CKV_AZURE_232:Single system pool keeps dev cost low; add a tainted user pool for production workloads
  name                = "aks-${local.name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "aks-${local.name}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.aks_sku_tier

  automatic_upgrade_channel    = "patch"
  node_os_upgrade_channel      = "NodeImage"
  local_account_disabled       = true
  azure_policy_enabled         = true
  oidc_issuer_enabled          = true
  workload_identity_enabled    = true
  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 48

  # Classic node pools + cluster autoscaler (not Node Auto-Provisioning)
  node_provisioning_profile {
    mode = "Manual"
  }

  default_node_pool {
    name                         = "system"
    vm_size                      = var.node_vm_size
    vnet_subnet_id               = azurerm_subnet.aks.id
    auto_scaling_enabled         = true
    min_count                    = var.node_min_count
    max_count                    = var.node_max_count
    max_pods                     = 50
    only_critical_addons_enabled = false
    temporary_name_for_rotation  = "tmpsystem"

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    load_balancer_sku   = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = local.tags
}
