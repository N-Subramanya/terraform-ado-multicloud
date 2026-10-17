variable "location" {
  description = "Azure region."
  type        = string
}

variable "aks_sku_tier" {
  description = "AKS control plane tier."
  type        = string
}

variable "node_vm_size" {
  description = "System node pool VM size."
  type        = string
}

variable "node_min_count" {
  description = "Minimum nodes."
  type        = number
}

variable "node_max_count" {
  description = "Maximum nodes."
  type        = number
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDRs allowed to reach the Kubernetes API."
  type        = list(string)
  default     = []
}

variable "admin_group_object_ids" {
  description = "Entra ID groups with cluster-admin."
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Log Analytics retention."
  type        = number
  default     = 30
}
