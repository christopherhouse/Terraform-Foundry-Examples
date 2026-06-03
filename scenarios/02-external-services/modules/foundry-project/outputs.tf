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
  value       = local.project_principal_id
}

output "project_capability_host_id" {
  description = "Resource ID of the project's capability host."
  value       = azapi_resource.project_capability_host.id
}
