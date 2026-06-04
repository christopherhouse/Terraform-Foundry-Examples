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
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

locals {
  project_name = "proj-${var.base_name}"
}

resource "azapi_resource" "project" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2026-03-01"
  parent_id = var.foundry_account_id
  name      = local.project_name
  location  = var.location

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      displayName = "Scenario 03 Private Foundry (${var.environment})"
      description = "Network-isolated Foundry project with VNet-injected Standard Agent and BYO Cosmos/Storage/Search."
    }
  }

  tags = var.tags

  schema_validation_enabled = false
  response_export_values    = ["identity.principalId", "properties.internalId"]
}

# Reformat the project's 32-char internalId into a UUID for the ABAC condition.
locals {
  internal_id_raw      = azapi_resource.project.output.properties.internalId
  project_id_guid      = "${substr(local.internal_id_raw, 0, 8)}-${substr(local.internal_id_raw, 8, 4)}-${substr(local.internal_id_raw, 12, 4)}-${substr(local.internal_id_raw, 16, 4)}-${substr(local.internal_id_raw, 20, 12)}"
  project_principal_id = azapi_resource.project.output.identity.principalId
}

# Let the project's system-assigned identity replicate through Entra before
# assigning roles to it.
resource "time_sleep" "wait_project_identity" {
  depends_on      = [azapi_resource.project]
  create_duration = "30s"
}

# Project connections ----------------------------------------------------------

resource "azapi_resource" "conn_cosmos" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2026-03-01"
  parent_id = azapi_resource.project.id
  name      = var.cosmos_account_name

  body = {
    properties = {
      category = "CosmosDb"
      target   = var.cosmos_account_endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.cosmos_account_id
        location   = var.location
      }
    }
  }

  schema_validation_enabled = false
}

resource "azapi_resource" "conn_storage" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2026-03-01"
  parent_id = azapi_resource.project.id
  name      = var.storage_account_name

  body = {
    properties = {
      category = "AzureStorageAccount"
      target   = var.storage_blob_endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.storage_account_id
        location   = var.location
      }
    }
  }

  schema_validation_enabled = false
}

resource "azapi_resource" "conn_search" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2026-03-01"
  parent_id = azapi_resource.project.id
  name      = var.ai_search_name

  body = {
    properties = {
      category = "CognitiveSearch"
      target   = "https://${var.ai_search_name}.search.windows.net"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ApiVersion = "2025-05-01-preview"
        ResourceId = var.ai_search_id
        location   = var.location
      }
    }
  }

  schema_validation_enabled = false
}

# App Insights is connected by API key (the connection string) rather than AAD —
# agents emit telemetry to the ingestion endpoint using this credential, so
# unlike the other three connections there's no project SMI RBAC needed.
resource "azapi_resource" "conn_app_insights" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2026-03-01"
  parent_id = azapi_resource.project.id
  name      = var.app_insights_name

  body = {
    properties = {
      category = "AppInsights"
      target   = var.app_insights_id
      authType = "ApiKey"
      credentials = {
        key = var.app_insights_connection_string
      }
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.app_insights_id
      }
    }
  }

  schema_validation_enabled = false
}

# Pre-capability-host role assignments -----------------------------------------
# These give the project SMI control plane access needed to provision the
# data resources the capability host will create (containers, role defs, etc).

resource "azurerm_role_assignment" "cosmos_operator" {
  name                 = uuidv5("dns", "${local.project_name}-${local.project_principal_id}-cosmos-operator")
  scope                = var.cosmos_account_id
  role_definition_name = "Cosmos DB Operator"
  principal_id         = local.project_principal_id

  depends_on = [time_sleep.wait_project_identity]
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  name                 = uuidv5("dns", "${local.project_name}-${local.project_principal_id}-${var.storage_account_name}-blob-contributor")
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.project_principal_id

  depends_on = [time_sleep.wait_project_identity]
}

resource "azurerm_role_assignment" "search_index_data_contributor" {
  name                 = uuidv5("dns", "${local.project_name}-${local.project_principal_id}-${var.ai_search_name}-index-contributor")
  scope                = var.ai_search_id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = local.project_principal_id

  depends_on = [time_sleep.wait_project_identity]
}

resource "azurerm_role_assignment" "search_service_contributor" {
  name                 = uuidv5("dns", "${local.project_name}-${local.project_principal_id}-${var.ai_search_name}-service-contributor")
  scope                = var.ai_search_id
  role_definition_name = "Search Service Contributor"
  principal_id         = local.project_principal_id

  depends_on = [time_sleep.wait_project_identity]
}

resource "time_sleep" "wait_rbac" {
  create_duration = "60s"

  depends_on = [
    azurerm_role_assignment.cosmos_operator,
    azurerm_role_assignment.storage_blob_data_contributor,
    azurerm_role_assignment.search_index_data_contributor,
    azurerm_role_assignment.search_service_contributor,
  ]
}

# Capability host --------------------------------------------------------------

resource "azapi_resource" "capability_host" {
  type      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  parent_id = azapi_resource.project.id
  name      = "caphost-${var.base_name}"

  body = {
    properties = {
      capabilityHostKind       = "Agents"
      vectorStoreConnections   = [var.ai_search_name]
      storageConnections       = [var.storage_account_name]
      threadStorageConnections = [var.cosmos_account_name]
    }
  }

  schema_validation_enabled = false

  depends_on = [
    azapi_resource.conn_cosmos,
    azapi_resource.conn_storage,
    azapi_resource.conn_search,
    azapi_resource.conn_app_insights,
    time_sleep.wait_rbac,
  ]
}

# Post-capability-host role assignments ----------------------------------------
# These target containers/scopes that the capability host provisions.

resource "azurerm_cosmosdb_sql_role_assignment" "project_data_contributor" {
  name                = uuidv5("dns", "${local.project_name}-${local.project_principal_id}-cosmos-sql-data-contributor")
  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
  scope               = var.cosmos_account_id
  role_definition_id  = "${var.cosmos_account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = local.project_principal_id

  depends_on = [azapi_resource.capability_host]
}

resource "azurerm_role_assignment" "storage_blob_data_owner_scoped" {
  name                 = uuidv5("dns", "${local.project_name}-${local.project_principal_id}-${var.storage_account_name}-blob-owner-scoped")
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = local.project_principal_id
  condition_version    = "2.0"
  condition            = <<-EOT
  (
    (
      !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags/read'})
      AND !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/filter/action'})
      AND !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags/write'})
    )
    OR
    (@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringStartsWithIgnoreCase '${local.project_id_guid}'
    AND @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringLikeIgnoreCase '*-azureml-agent')
  )
  EOT

  depends_on = [azapi_resource.capability_host]
}
