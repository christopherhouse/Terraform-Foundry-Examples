variable "resource_group_name" {
  description = "Resource group that holds the data resources."
  type        = string
}

variable "resource_group_id" {
  description = "Resource group ID (used as parent for azapi resources)."
  type        = string
}

variable "location" {
  description = "Azure region for the data resources."
  type        = string
}

variable "base_name" {
  description = "CAF base name used for child resource naming (e.g. foundry-s02-dev-wus3-001)."
  type        = string
}

variable "base_name_flat" {
  description = "Flattened base name (no hyphens, lowercase) for resources with restricted naming (storage, KV)."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
}
