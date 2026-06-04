terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

locals {
  law_name          = "log-${var.base_name}"
  app_insights_name = "appi-${var.base_name}"
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.law_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = var.tags
}

# Using azapi instead of azurerm_application_insights to dodge the v4 provider's
# `billing/features` 404 (the API endpoint is gone for newer components).
resource "azapi_resource" "app_insights" {
  type      = "Microsoft.Insights/components@2020-02-02"
  parent_id = var.resource_group_id
  name      = local.app_insights_name
  location  = var.location

  body = {
    kind = "web"
    properties = {
      Application_Type    = "web"
      WorkspaceResourceId = azurerm_log_analytics_workspace.this.id
    }
  }

  tags = var.tags

  schema_validation_enabled = false
  response_export_values    = ["properties.ConnectionString"]
}
