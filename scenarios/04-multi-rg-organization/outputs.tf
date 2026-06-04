output "resource_group_name_net" {
  description = "Name of the network RG (VNet, subnets, private DNS zones)."
  value       = azurerm_resource_group.net.name
}

output "resource_group_name_data" {
  description = "Name of the data RG (Storage, Cosmos, AI Search and their PEs)."
  value       = azurerm_resource_group.data.name
}

output "resource_group_name_ai" {
  description = "Name of the AI RG (Foundry account, deployments, project, capability host, account PE)."
  value       = azurerm_resource_group.ai.name
}

output "vnet_id" {
  description = "Resource ID of the scenario VNet (in rg-net)."
  value       = module.network.vnet_id
}

output "agent_subnet_id" {
  description = "Resource ID of the agent (Microsoft.App-delegated) subnet."
  value       = module.network.agent_subnet_id
}

output "private_endpoint_subnet_id" {
  description = "Resource ID of the private endpoint subnet."
  value       = module.network.private_endpoint_subnet_id
}

output "foundry_account_name" {
  description = "Name of the Foundry account (in rg-ai)."
  value       = module.foundry_account.account_name
}

output "foundry_account_id" {
  description = "Resource ID of the Foundry account."
  value       = module.foundry_account.account_id
}

output "foundry_project_name" {
  description = "Name of the Foundry project (child of the account in rg-ai)."
  value       = module.foundry_project.project_name
}

output "foundry_project_id" {
  description = "Resource ID of the Foundry project."
  value       = module.foundry_project.project_id
}

output "storage_account_name" {
  description = "Name of the agent data storage account (in rg-data)."
  value       = module.data_resources.storage_account_name
}

output "cosmos_account_name" {
  description = "Name of the agent thread Cosmos DB account (in rg-data)."
  value       = module.data_resources.cosmos_account_name
}

output "ai_search_name" {
  description = "Name of the agent vector store AI Search service (in rg-data)."
  value       = module.data_resources.ai_search_name
}
