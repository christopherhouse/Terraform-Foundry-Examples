output "account_id" {
  description = "Resource ID of the Foundry (Cognitive Services AIServices) account."
  value       = azapi_resource.foundry_account.id

  # Block consumers (PE, project) until the account reaches Succeeded.
  depends_on = [time_sleep.wait_account_ready]
}

output "account_name" {
  description = "Name of the Foundry account."
  value       = azapi_resource.foundry_account.name

  depends_on = [time_sleep.wait_account_ready]
}

output "account_principal_id" {
  description = "Principal ID of the Foundry account's system-assigned identity."
  value       = azapi_resource.foundry_account.output.identity.principalId

  depends_on = [time_sleep.wait_account_ready]
}

output "account_endpoint" {
  description = "Primary endpoint of the Foundry account."
  value       = try(azapi_resource.foundry_account.output.properties.endpoint, null)

  depends_on = [time_sleep.wait_account_ready]
}

output "gpt4o_deployment_name" {
  description = "Name of the gpt-4o deployment."
  value       = azapi_resource.gpt4o.name
}

output "embedding_deployment_name" {
  description = "Name of the text-embedding-3-large deployment."
  value       = azapi_resource.text_embedding_3_large.name
}
