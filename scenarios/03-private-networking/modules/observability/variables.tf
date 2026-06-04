variable "resource_group_name" {
  description = "Resource group for the Log Analytics workspace and App Insights component."
  type        = string
}

variable "resource_group_id" {
  description = "Resource group ID, used as parent_id for the App Insights azapi resource."
  type        = string
}

variable "location" {
  description = "Azure region for the observability resources."
  type        = string
}

variable "base_name" {
  description = "CAF base name."
  type        = string
}

variable "tags" {
  description = "Tags to apply to module-managed resources."
  type        = map(string)
  default     = {}
}
