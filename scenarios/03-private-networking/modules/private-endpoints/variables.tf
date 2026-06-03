variable "resource_group_name" {
  description = "Resource group for the private endpoints."
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
  description = "Subnet ID hosting the private endpoints."
  type        = string
}

variable "storage_account_id" {
  description = "Resource ID of the storage account."
  type        = string
}

variable "cosmos_account_id" {
  description = "Resource ID of the Cosmos DB account."
  type        = string
}

variable "ai_search_id" {
  description = "Resource ID of the AI Search service."
  type        = string
}

variable "foundry_account_id" {
  description = "Resource ID of the Foundry account."
  type        = string
}

variable "dns_zone_id_blob" {
  description = "Resource ID of the privatelink.blob.core.windows.net DNS zone."
  type        = string
}

variable "dns_zone_id_cosmos" {
  description = "Resource ID of the privatelink.documents.azure.com DNS zone."
  type        = string
}

variable "dns_zone_id_search" {
  description = "Resource ID of the privatelink.search.windows.net DNS zone."
  type        = string
}

variable "dns_zone_id_cognitive_services" {
  description = "Resource ID of the privatelink.cognitiveservices.azure.com DNS zone."
  type        = string
}

variable "dns_zone_id_ai_services" {
  description = "Resource ID of the privatelink.services.ai.azure.com DNS zone."
  type        = string
}

variable "dns_zone_id_openai" {
  description = "Resource ID of the privatelink.openai.azure.com DNS zone."
  type        = string
}

variable "tags" {
  description = "Tags to apply to module-managed resources."
  type        = map(string)
  default     = {}
}
