output "resource_group_name" {
  description = "Name of the resource group hosting the Foundry deployment."
  value       = azurerm_resource_group.this.name
}

output "foundry_account_name" {
  description = "Name of the Foundry (Microsoft.CognitiveServices AIServices) account."
  value       = azurerm_cognitive_account.this.name
}

output "foundry_account_id" {
  description = "Resource ID of the Foundry account."
  value       = azurerm_cognitive_account.this.id
}

output "foundry_account_endpoint" {
  description = "Primary endpoint of the Foundry account."
  value       = azurerm_cognitive_account.this.endpoint
}

output "foundry_project_name" {
  description = "Name of the Foundry project."
  value       = azurerm_cognitive_account_project.this.name
}

output "foundry_project_id" {
  description = "Resource ID of the Foundry project."
  value       = azurerm_cognitive_account_project.this.id
}

output "gpt4o_deployment_name" {
  description = "Name of the gpt-4o model deployment on the Foundry account."
  value       = azurerm_cognitive_deployment.gpt4o.name
}

output "gpt4o_deployment_capacity" {
  description = "Capacity (1K TPM units) provisioned for the gpt-4o deployment."
  value       = var.gpt4o_capacity
}
