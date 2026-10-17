output "resource_group_name" {
  description = "Resource group name."
  value       = module.azure.resource_group_name
}

output "aks_name" {
  description = "AKS cluster name."
  value       = module.azure.aks_name
}

output "aks_get_credentials" {
  description = "Command to fetch kubeconfig."
  value       = module.azure.aks_get_credentials
}
