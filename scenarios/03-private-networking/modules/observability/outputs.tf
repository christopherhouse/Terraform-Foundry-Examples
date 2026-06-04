output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "app_insights_id" {
  description = "Resource ID of the App Insights component."
  value       = azapi_resource.app_insights.id
}

output "app_insights_name" {
  description = "Name of the App Insights component."
  value       = azapi_resource.app_insights.name
}

output "app_insights_connection_string" {
  description = "Connection string of the App Insights component (used in the AppInsights project connection)."
  value       = azapi_resource.app_insights.output.properties.ConnectionString
  sensitive   = true
}
