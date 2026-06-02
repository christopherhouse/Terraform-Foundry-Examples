output "vnet_id" {
  description = "Resource ID of the VNet."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the VNet."
  value       = azurerm_virtual_network.this.name
}

output "agent_subnet_id" {
  description = "Resource ID of the Microsoft.App-delegated agent subnet."
  value       = azurerm_subnet.agent.id
}

output "private_endpoint_subnet_id" {
  description = "Resource ID of the private endpoint subnet."
  value       = azurerm_subnet.private_endpoint.id
}

output "dns_zone_ids" {
  description = "Map of private DNS zone resource IDs keyed by short name (blob, cosmos, search, cognitive_services, ai_services, openai)."
  value = {
    for k, z in azurerm_private_dns_zone.this : k => z.id
  }
}
