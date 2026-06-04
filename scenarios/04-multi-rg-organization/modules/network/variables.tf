variable "resource_group_name" {
  description = "Resource group to deploy the VNet and DNS zones into."
  type        = string
}

variable "location" {
  description = "Azure region for the VNet."
  type        = string
}

variable "base_name" {
  description = "CAF base name used for child resource naming (e.g. foundry-s03-dev-wus3-001)."
  type        = string
}

variable "vnet_address_space" {
  description = "CIDR block for the VNet."
  type        = string
}

variable "agent_subnet_prefix" {
  description = "CIDR for the agent (Microsoft.App-delegated) subnet."
  type        = string
}

variable "private_endpoint_subnet_prefix" {
  description = "CIDR for the private endpoint subnet."
  type        = string
}

variable "tags" {
  description = "Tags to apply to module-managed resources."
  type        = map(string)
  default     = {}
}
