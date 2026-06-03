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

# Data resources — IDs needed for project-SMI RBAC; names needed for capability
# host references (connections themselves are defined at account scope).

variable "storage_account_id" {
  description = "Resource ID of the storage account the project uses for file storage."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account / inherited connection name."
  type        = string
}

variable "cosmos_account_id" {
  description = "Resource ID of the Cosmos account the project uses for thread storage."
  type        = string
}

variable "cosmos_account_name" {
  description = "Name of the Cosmos account / inherited connection name."
  type        = string
}

variable "ai_search_id" {
  description = "Resource ID of the AI Search service the project uses for vector store."
  type        = string
}

variable "ai_search_name" {
  description = "Name of the AI Search service / inherited connection name."
  type        = string
}

variable "tags" {
  description = "Tags to apply to module-managed resources."
  type        = map(string)
  default     = {}
}
