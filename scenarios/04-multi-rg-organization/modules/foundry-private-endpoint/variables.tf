variable "resource_group_name" {
  description = "Resource group for the Foundry private endpoint (typically the AI RG, alongside the Foundry account)."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "base_name" {
  description = "CAF base name used in private endpoint naming."
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID hosting the private endpoint. Lives in the network RG."
  type        = string
}

variable "foundry_account_id" {
  description = "Resource ID of the Foundry account."
  type        = string
}

variable "dns_zone_id_cognitive_services" {
  description = "Resource ID of the privatelink.cognitiveservices.azure.com DNS zone (in the network RG)."
  type        = string
}

variable "dns_zone_id_ai_services" {
  description = "Resource ID of the privatelink.services.ai.azure.com DNS zone (in the network RG)."
  type        = string
}

variable "dns_zone_id_openai" {
  description = "Resource ID of the privatelink.openai.azure.com DNS zone (in the network RG)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to module-managed resources."
  type        = map(string)
  default     = {}
}
