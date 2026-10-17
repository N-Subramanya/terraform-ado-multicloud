variable "project" {
  description = "Short project name used in resource names."
  type        = string
  default     = "multicloud"
}

variable "environment" {
  description = "Environment name (dev, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "vnet_cidr" {
  description = "Address space of the virtual network."
  type        = string
  default     = "10.40.0.0/16"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. null = latest supported by the region."
  type        = string
  default     = null
}

variable "aks_sku_tier" {
  description = "AKS control plane tier: Free (dev) or Standard (prod, uptime SLA)."
  type        = string
  default     = "Free"
}

variable "node_vm_size" {
  description = "VM size of the system node pool."
  type        = string
  default     = "Standard_B2s"
}

variable "node_min_count" {
  description = "Minimum nodes (autoscaler)."
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum nodes (autoscaler)."
  type        = number
  default     = 3
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDRs allowed to reach the Kubernetes API server. Empty = open (dev only)."
  type        = list(string)
  default     = []
}

variable "admin_group_object_ids" {
  description = "Entra ID group object IDs granted cluster-admin via Azure RBAC."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Log Analytics retention in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Extra tags applied to every resource."
  type        = map(string)
  default     = {}
}
