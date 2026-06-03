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
      displayName = "Scenario 02 External Services (${var.environment})"
      description = "Public-network Foundry project with BYO Storage / Cosmos / Search / Key Vault / Application Insights wired as account-scoped connections."
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

# Pre-capability-host role assignments -----------------------------------------
# Give the project SMI control plane access on the BYO resources so the
# capability host can provision containers, role defs, etc.

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

# Project capability host ------------------------------------------------------
# References the connection NAMES that the project inherits from the account.

resource "azapi_resource" "project_capability_host" {
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
    time_sleep.wait_rbac,
  ]
}

# Post-capability-host role assignments ----------------------------------------
# Target containers / scopes that the capability host provisions.

resource "azurerm_cosmosdb_sql_role_assignment" "project_data_contributor" {
  name                = uuidv5("dns", "${local.project_name}-${local.project_principal_id}-cosmos-sql-data-contributor")
  resource_group_name = var.resource_group_name
  account_name        = var.cosmos_account_name
  scope               = var.cosmos_account_id
  role_definition_id  = "${var.cosmos_account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = local.project_principal_id

  depends_on = [azapi_resource.project_capability_host]
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

  depends_on = [azapi_resource.project_capability_host]
}
