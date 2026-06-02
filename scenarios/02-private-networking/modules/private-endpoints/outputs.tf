output "storage_blob_pe_id" {
  description = "Resource ID of the storage blob private endpoint."
  value       = azurerm_private_endpoint.storage_blob.id
}

output "cosmos_pe_id" {
  description = "Resource ID of the Cosmos DB private endpoint."
  value       = azurerm_private_endpoint.cosmos.id
}

output "search_pe_id" {
  description = "Resource ID of the AI Search private endpoint."
  value       = azurerm_private_endpoint.search.id
}

output "foundry_pe_id" {
  description = "Resource ID of the Foundry account private endpoint."
  value       = azurerm_private_endpoint.foundry.id
}
