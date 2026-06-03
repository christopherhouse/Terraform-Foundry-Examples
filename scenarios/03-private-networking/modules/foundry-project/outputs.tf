output "project_id" {
  description = "Resource ID of the Foundry project."
  value       = azapi_resource.project.id
}

output "project_name" {
  description = "Name of the Foundry project."
  value       = azapi_resource.project.name
}

output "project_principal_id" {
  description = "Principal ID of the project's system-assigned identity."
  value       = azapi_resource.project.output.identity.principalId
}

output "capability_host_id" {
  description = "Resource ID of the project-level capability host."
  value       = azapi_resource.capability_host.id
}
