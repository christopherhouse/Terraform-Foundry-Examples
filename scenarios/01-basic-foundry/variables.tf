variable "location" {
  description = "Azure region for the deployment."
  type        = string
  default     = "eastus2"
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
  description = "Scenario identifier embedded in resource names (e.g. s01)."
  type        = string
  default     = "s01"
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
