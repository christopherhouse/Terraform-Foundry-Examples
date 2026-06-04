variable "resource_group_name" {
  description = "Resource group for the data-resource private endpoints (typically the data RG, alongside their target resources)."
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
  description = "Subnet ID hosting the private endpoints. Lives in the network RG."
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

variable "dns_zone_id_blob" {
  description = "Resource ID of the privatelink.blob.core.windows.net DNS zone (in the network RG)."
  type        = string
}

variable "dns_zone_id_cosmos" {
  description = "Resource ID of the privatelink.documents.azure.com DNS zone (in the network RG)."
  type        = string
}

variable "dns_zone_id_search" {
  description = "Resource ID of the privatelink.search.windows.net DNS zone (in the network RG)."
  type        = string
}

variable "tags" {
  description = "Tags to apply to module-managed resources."
  type        = map(string)
  default     = {}
}
