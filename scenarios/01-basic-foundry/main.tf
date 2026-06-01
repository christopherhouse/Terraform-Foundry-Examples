locals {
  region_short = {
    eastus        = "eus"
    eastus2       = "eus2"
    westus2       = "wus2"
    westus3       = "wus3"
    swedencentral = "swc"
    northeurope   = "neu"
    westeurope    = "weu"
  }
  region_abbr = lookup(local.region_short, var.location, var.location)

  base_name = "${var.workload}-${var.scenario_id}-${var.environment}-${local.region_abbr}-${var.instance}"

  rg_name      = "rg-${local.base_name}"
  account_name = "cog-${local.base_name}"
  project_name = "proj-${local.base_name}"

  default_tags = {
    Workload    = var.workload
    Scenario    = var.scenario_id
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repo        = "christopherhouse/Terraform-Foundry-Examples"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = var.location
  tags     = local.tags
}

resource "azapi_resource" "foundry_account" {
  type      = "Microsoft.CognitiveServices/accounts@2026-03-01"
  parent_id = azurerm_resource_group.this.id
  name      = local.account_name
  location  = var.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    kind = "AIServices"
    sku = {
      name = "S0"
    }
    properties = {
      allowProjectManagement = true
      customSubDomainName    = local.account_name
      disableLocalAuth       = true
      publicNetworkAccess    = "Enabled"
    }
  }

  tags = local.tags

  schema_validation_enabled = false
  response_export_values    = ["properties.endpoint", "properties.endpoints"]
}

resource "azapi_resource" "foundry_project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2026-03-01"
  parent_id = azapi_resource.foundry_account.id
  name      = local.project_name
  location  = var.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      displayName = "Scenario 01 Basic Foundry (${var.environment})"
      description = "Basic Foundry project deployed by Terraform-Foundry-Examples scenario 01."
    }
  }

  tags = local.tags

  schema_validation_enabled = false
  response_export_values    = ["properties"]
}
