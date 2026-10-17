output "resource_group_name" {
  description = "Resource group containing all Azure resources."
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "Virtual network ID."
  value       = azurerm_virtual_network.this.id
}

output "aks_name" {
  description = "AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "aks_get_credentials" {
  description = "Command to fetch kubeconfig (Entra ID auth)."
  value       = "az aks get-credentials -g ${azurerm_resource_group.this.name} -n ${azurerm_kubernetes_cluster.this.name}"
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace used by Container Insights."
  value       = azurerm_log_analytics_workspace.this.id
}
