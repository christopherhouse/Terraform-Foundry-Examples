output "storage_account_id" {
  description = "Resource ID of the storage account."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.this.name
}

output "storage_blob_endpoint" {
  description = "Primary blob endpoint of the storage account."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "cosmos_account_id" {
  description = "Resource ID of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.id
}

output "cosmos_account_name" {
  description = "Name of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.name
}

output "cosmos_account_endpoint" {
  description = "Document endpoint of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "ai_search_id" {
  description = "Resource ID of the AI Search service."
  value       = azapi_resource.ai_search.id
}

output "ai_search_name" {
  description = "Name of the AI Search service."
  value       = azapi_resource.ai_search.name
}

output "ai_search_identity_principal_id" {
  description = "Principal ID of the AI Search service's system-assigned managed identity."
  value       = azapi_resource.ai_search.output.identity.principalId
}
