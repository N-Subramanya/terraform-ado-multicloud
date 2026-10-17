# prod: uptime SLA, bigger nodes, at least 2 nodes
location           = "eastus"
aks_sku_tier       = "Standard"
node_vm_size       = "Standard_D2s_v5"
node_min_count     = 2
node_max_count     = 5
log_retention_days = 90

# Restrict the API server to your office / VPN ranges, e.g. ["203.0.113.0/24"]
api_server_authorized_ip_ranges = []

# Entra ID group(s) that get cluster-admin, e.g. ["00000000-0000-0000-0000-000000000000"]
admin_group_object_ids = []
