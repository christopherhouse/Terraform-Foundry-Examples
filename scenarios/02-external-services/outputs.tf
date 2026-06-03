output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "foundry_account_id" {
  value = module.foundry_account.account_id
}

output "foundry_account_name" {
  value = module.foundry_account.account_name
}

output "foundry_account_endpoint" {
  value = module.foundry_account.account_endpoint
}

output "foundry_project_id" {
  value = module.foundry_project.project_id
}

output "foundry_project_name" {
  value = module.foundry_project.project_name
}

output "storage_account_name" {
  value = module.data_resources.storage_account_name
}

output "cosmos_account_name" {
  value = module.data_resources.cosmos_account_name
}

output "ai_search_name" {
  value = module.data_resources.ai_search_name
}

output "key_vault_name" {
  value = module.data_resources.key_vault_name
}

output "key_vault_uri" {
  value = module.data_resources.key_vault_uri
}

output "app_insights_name" {
  value = module.data_resources.app_insights_name
}

output "log_analytics_workspace_id" {
  value = module.data_resources.log_analytics_workspace_id
}
