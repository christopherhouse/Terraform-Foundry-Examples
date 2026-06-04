output "resource_group_name" {
  description = "Name of the resource group hosting the scenario."
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "Resource ID of the scenario VNet."
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
  description = "Name of the Foundry account."
  value       = module.foundry_account.account_name
}

output "foundry_account_id" {
  description = "Resource ID of the Foundry account."
  value       = module.foundry_account.account_id
}

output "foundry_project_name" {
  description = "Name of the Foundry project."
  value       = module.foundry_project.project_name
}

output "foundry_project_id" {
  description = "Resource ID of the Foundry project."
  value       = module.foundry_project.project_id
}

output "storage_account_name" {
  description = "Name of the agent data storage account."
  value       = module.data_resources.storage_account_name
}

output "cosmos_account_name" {
  description = "Name of the agent thread Cosmos DB account."
  value       = module.data_resources.cosmos_account_name
}

output "ai_search_name" {
  description = "Name of the agent vector store AI Search service."
  value       = module.data_resources.ai_search_name
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace backing App Insights."
  value       = module.observability.log_analytics_workspace_name
}

output "app_insights_name" {
  description = "Name of the App Insights component connected to the Foundry project."
  value       = module.observability.app_insights_name
}
