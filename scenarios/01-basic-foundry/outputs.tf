output "resource_group_name" {
  description = "Name of the resource group hosting the Foundry deployment."
  value       = azurerm_resource_group.this.name
}

output "foundry_account_name" {
  description = "Name of the Foundry (Microsoft.CognitiveServices AIServices) account."
  value       = azapi_resource.foundry_account.name
}

output "foundry_account_id" {
  description = "Resource ID of the Foundry account."
  value       = azapi_resource.foundry_account.id
}

output "foundry_account_endpoint" {
  description = "Primary endpoint of the Foundry account."
  value       = try(azapi_resource.foundry_account.output.properties.endpoint, null)
}

output "foundry_project_name" {
  description = "Name of the Foundry project."
  value       = azapi_resource.foundry_project.name
}

output "foundry_project_id" {
  description = "Resource ID of the Foundry project."
  value       = azapi_resource.foundry_project.id
}

output "gpt4o_deployment_name" {
  description = "Name of the gpt-4o model deployment on the Foundry account."
  value       = azapi_resource.gpt4o.name
}

output "gpt4o_deployment_capacity" {
  description = "Capacity (1K TPM units) provisioned for the gpt-4o deployment."
  value       = var.gpt4o_capacity
}
