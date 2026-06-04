variable "resource_group_name" {
  description = "Resource group for the data plane role assignments."
  type        = string
}

variable "location" {
  description = "Azure region for project metadata."
  type        = string
}

variable "base_name" {
  description = "CAF base name."
  type        = string
}

variable "environment" {
  description = "Environment short name, used in the project display name."
  type        = string
}

variable "foundry_account_id" {
  description = "Resource ID of the parent Foundry account."
  type        = string
}

variable "foundry_account_name" {
  description = "Name of the parent Foundry account."
  type        = string
}

variable "storage_account_id" {
  description = "Resource ID of the storage account the project connects to."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account."
  type        = string
}

variable "storage_blob_endpoint" {
  description = "Primary blob endpoint of the storage account."
  type        = string
}

variable "cosmos_account_id" {
  description = "Resource ID of the Cosmos account the project connects to."
  type        = string
}

variable "cosmos_account_name" {
  description = "Name of the Cosmos account."
  type        = string
}

variable "cosmos_account_endpoint" {
  description = "Document endpoint of the Cosmos account."
  type        = string
}

variable "ai_search_id" {
  description = "Resource ID of the AI Search service the project connects to."
  type        = string
}

variable "ai_search_name" {
  description = "Name of the AI Search service."
  type        = string
}

variable "app_insights_id" {
  description = "Resource ID of the App Insights component the project connects to."
  type        = string
}

variable "app_insights_name" {
  description = "Name of the App Insights component (used as the connection name)."
  type        = string
}

variable "app_insights_connection_string" {
  description = "Connection string credential for the AppInsights project connection."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to module-managed resources."
  type        = map(string)
  default     = {}
}
