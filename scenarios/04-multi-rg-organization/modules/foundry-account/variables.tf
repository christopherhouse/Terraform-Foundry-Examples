variable "resource_group_id" {
  description = "Resource group ID, used as the Foundry account parent."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name, used for the destroy-time purge action."
  type        = string
}

variable "location" {
  description = "Azure region for the Foundry account."
  type        = string
}

variable "base_name" {
  description = "CAF base name."
  type        = string
}

variable "agent_subnet_id" {
  description = "Resource ID of the Microsoft.App-delegated agent subnet to inject the Foundry account into."
  type        = string
}

variable "gpt4o_sku_name" {
  description = "SKU name for the gpt-4o deployment."
  type        = string
}

variable "gpt4o_capacity" {
  description = "Capacity for the gpt-4o deployment."
  type        = number
}

variable "gpt4o_model_version" {
  description = "Model version for gpt-4o (null = region default)."
  type        = string
  default     = null
}

variable "embedding_sku_name" {
  description = "SKU name for the text-embedding-3-large deployment."
  type        = string
}

variable "embedding_capacity" {
  description = "Capacity for the text-embedding-3-large deployment."
  type        = number
}

variable "embedding_model_version" {
  description = "Model version for text-embedding-3-large (null = region default)."
  type        = string
  default     = null
}

variable "foundry_users" {
  description = "Principals granted the Foundry User role on the Foundry account."
  type = list(object({
    object_id      = string
    principal_type = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to module-managed resources."
  type        = map(string)
  default     = {}
}
