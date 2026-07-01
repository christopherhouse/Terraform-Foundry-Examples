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

data "azurerm_client_config" "current" {}

locals {
  storage_account_name = substr("st${var.base_name_flat}", 0, 24)
  cosmos_account_name  = "cosno-${var.base_name}"
  search_service_name  = "srch-${var.base_name}"
  key_vault_name       = substr("kv-${var.base_name_flat}", 0, 24)
  law_name             = "log-${var.base_name}"
  app_insights_name    = "appi-${var.base_name}"
}

resource "azurerm_storage_account" "this" {
  name                = local.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  shared_access_key_enabled       = false
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true

  tags = var.tags
}

resource "azurerm_cosmosdb_account" "this" {
  name                = local.cosmos_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  offer_type        = "Standard"
  kind              = "GlobalDocumentDB"
  free_tier_enabled = false

  local_authentication_disabled = true
  public_network_access_enabled = true

  automatic_failover_enabled       = false
  multiple_write_locations_enabled = false

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = false
  }

  tags = var.tags
}

resource "azapi_resource" "ai_search" {
  type      = "Microsoft.Search/searchServices@2025-05-01"
  name      = local.search_service_name
  parent_id = var.resource_group_id
  location  = var.location

  body = {
    sku = {
      name = "standard"
    }
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      replicaCount   = 1
      partitionCount = 1
      hostingMode    = "Default"
      semanticSearch = "free"

      disableLocalAuth = false
      authOptions = {
        aadOrApiKey = {
          aadAuthFailureMode = "http401WithBearerChallenge"
        }
      }

      publicNetworkAccess = "Enabled"
    }
  }

  tags = var.tags

  response_export_values = ["identity.principalId"]

  # AI Search creates in westus3 have intermittently taken >30m (azapi default).
  timeouts {
    create = "60m"
  }
}

resource "azurerm_key_vault" "this" {
  name                = local.key_vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  public_network_access_enabled = true

  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  tags = var.tags
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
