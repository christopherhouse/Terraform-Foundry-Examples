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

# Model deployments

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

# Account-scoped connections — inherited by every project on the account.

variable "storage_account_id" {
  description = "Storage account resource ID for the AzureStorageAccount connection."
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name (used as the connection name)."
  type        = string
}

variable "storage_blob_endpoint" {
  description = "Storage blob endpoint URL for the connection target."
  type        = string
}

variable "cosmos_account_id" {
  description = "Cosmos DB account resource ID."
  type        = string
}

variable "cosmos_account_name" {
  description = "Cosmos DB account name (used as the connection name)."
  type        = string
}

variable "cosmos_account_endpoint" {
  description = "Cosmos DB document endpoint URL for the connection target."
  type        = string
}

variable "ai_search_id" {
  description = "AI Search service resource ID."
  type        = string
}

variable "ai_search_name" {
  description = "AI Search service name (used as the connection name)."
  type        = string
}

variable "ai_search_identity_principal_id" {
  description = "Principal ID of the AI Search service's system-assigned identity. Granted Cognitive Services OpenAI User on the account so integrated vectorization can call the embedding deployment."
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault resource ID."
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault name (used as the connection name)."
  type        = string
}

variable "app_insights_id" {
  description = "Application Insights resource ID."
  type        = string
}

variable "app_insights_name" {
  description = "Application Insights name (used as the connection name)."
  type        = string
}

variable "app_insights_connection_string" {
  description = "Application Insights connection string. Stored as the connection's credential.key."
  type        = string
  sensitive   = true
}

# Access

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
