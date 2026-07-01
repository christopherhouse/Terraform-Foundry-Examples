variable "location" {
  description = "Azure region for the deployment. westus3 has the broadest model + capacity availability."
  type        = string
  default     = "westus3"
}

variable "environment" {
  description = "Environment short name (dev, test, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, prod."
  }
}

variable "workload" {
  description = "Workload name segment used in CAF resource naming."
  type        = string
  default     = "foundry"
}

variable "scenario_id" {
  description = "Scenario identifier embedded in resource names (e.g. s02)."
  type        = string
  default     = "s02"
}

variable "instance" {
  description = "Three-digit instance number used to disambiguate parallel deployments."
  type        = string
  default     = "001"
}

variable "tags" {
  description = "Additional tags merged onto the default tag set applied to every resource."
  type        = map(string)
  default     = {}
}

# Model deployments

variable "gpt4o_sku_name" {
  description = "SKU name for the gpt-4o deployment (Standard, GlobalStandard, DataZoneStandard, ProvisionedManaged)."
  type        = string
  default     = "GlobalStandard"
}

variable "gpt4o_capacity" {
  description = "Capacity for the gpt-4o deployment, in 1K TPM units."
  type        = number
  default     = 50
}

variable "gpt4o_model_version" {
  description = "Model version for gpt-4o. Leave null to use the region default."
  type        = string
  default     = null
}

variable "embedding_sku_name" {
  description = "SKU name for the text-embedding-3-large deployment."
  type        = string
  default     = "Standard"
}

variable "embedding_capacity" {
  description = "Capacity for the text-embedding-3-large deployment, in 1K TPM units. Knowledge-source ingestion embeds chunks in bursts, so keep headroom to avoid 429s (50 throttles on document uploads)."
  type        = number
  default     = 150
}

variable "embedding_model_version" {
  description = "Model version for text-embedding-3-large. Leave null to use the region default."
  type        = string
  default     = null
}

# Access

variable "foundry_users" {
  description = "Principals granted the Foundry User role on the Foundry account (data-plane AI access)."
  type = list(object({
    object_id      = string
    principal_type = string
  }))
  default = [
    {
      object_id      = "2ede4c0c-360b-47f8-80b0-bdba8badea7b"
      principal_type = "User"
    },
  ]

  validation {
    condition = alltrue([
      for u in var.foundry_users :
      contains(["User", "Group", "ServicePrincipal", "ForeignGroup", "Device"], u.principal_type)
    ])
    error_message = "Each entry's principal_type must be one of: User, Group, ServicePrincipal, ForeignGroup, Device."
  }
}
