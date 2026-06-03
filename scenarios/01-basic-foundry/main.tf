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

  # Per Microsoft docs, reference the role by ID (not name) during the
  # Foundry RBAC rename rollout. https://learn.microsoft.com/azure/foundry/concepts/rbac-foundry
  foundry_user_role_id = "53ca6127-db72-4b80-b1b0-d745d6d5456d"
}

resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_cognitive_account" "this" {
  name                = local.account_name
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location

  kind     = "AIServices"
  sku_name = "S0"

  custom_subdomain_name         = local.account_name
  local_auth_enabled            = false
  public_network_access_enabled = true
  project_management_enabled    = true

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_cognitive_account_project" "this" {
  name                 = local.project_name
  cognitive_account_id = azurerm_cognitive_account.this.id
  location             = var.location

  display_name = "Scenario 01 Basic Foundry (${var.environment})"
  description  = "Basic Foundry project deployed by Terraform-Foundry-Examples scenario 01."

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_role_assignment" "foundry_user" {
  for_each = { for u in var.foundry_users : u.object_id => u }

  scope              = azurerm_cognitive_account.this.id
  role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/${local.foundry_user_role_id}"
  principal_id       = each.value.object_id
  principal_type     = each.value.principal_type
}

resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.this.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = var.gpt4o_model_version
  }

  sku {
    name     = var.gpt4o_sku_name
    capacity = var.gpt4o_capacity
  }

  # The variable documents null as "use the region default" — let Azure pick
  # and ignore the value it records back into state.
  lifecycle {
    ignore_changes = [model[0].version]
  }
}
