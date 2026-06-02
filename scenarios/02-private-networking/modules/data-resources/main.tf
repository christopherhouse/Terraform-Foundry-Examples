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
  storage_account_name = substr("st${var.base_name_flat}", 0, 24)
  cosmos_account_name  = "cosno-${var.base_name}"
  search_service_name  = "srch-${var.base_name}"
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
  public_network_access_enabled   = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

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
  public_network_access_enabled = false

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
      semanticSearch = "disabled"

      disableLocalAuth = false
      authOptions = {
        aadOrApiKey = {
          aadAuthFailureMode = "http401WithBearerChallenge"
        }
      }

      publicNetworkAccess = "disabled"
      networkRuleSet = {
        bypass = "None"
      }
    }
  }

  tags = var.tags

  response_export_values = ["identity.principalId"]
}
