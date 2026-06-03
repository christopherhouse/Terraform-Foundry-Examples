variable "resource_group_name" {
  description = "Resource group for storage, Cosmos, and AI Search."
  type        = string
}

variable "resource_group_id" {
  description = "Resource group ID, used as parent_id for azapi resources."
  type        = string
}

variable "location" {
  description = "Azure region for the data resources."
  type        = string
}

variable "base_name" {
  description = "CAF base name (hyphenated). Used for resources that accept hyphens."
  type        = string
}

variable "base_name_flat" {
  description = "CAF base name flattened to lowercase alphanumeric. Used for storage account naming."
  type        = string
}

variable "tags" {
  description = "Tags to apply to module-managed resources."
  type        = map(string)
  default     = {}
}
