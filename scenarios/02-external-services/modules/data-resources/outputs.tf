output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "storage_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}

output "cosmos_account_id" {
  value = azurerm_cosmosdb_account.this.id
}

output "cosmos_account_name" {
  value = azurerm_cosmosdb_account.this.name
}

output "cosmos_account_endpoint" {
  value = azurerm_cosmosdb_account.this.endpoint
}

output "ai_search_id" {
  value = azapi_resource.ai_search.id
}

output "ai_search_name" {
  value = azapi_resource.ai_search.name
}

output "key_vault_id" {
  value = azurerm_key_vault.this.id
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "app_insights_id" {
  value = azurerm_application_insights.this.id
}

output "app_insights_name" {
  value = azurerm_application_insights.this.name
}

output "app_insights_connection_string" {
  value     = azurerm_application_insights.this.connection_string
  sensitive = true
}
