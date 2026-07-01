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

data "azurerm_client_config" "current" {}

locals {
  account_name = "cog-${var.base_name}"

  # Per Microsoft docs, reference the role by ID (not name) during the
  # Foundry RBAC rename rollout. https://learn.microsoft.com/azure/foundry/concepts/rbac-foundry
  foundry_user_role_id = "53ca6127-db72-4b80-b1b0-d745d6d5456d"
}

resource "azapi_resource" "foundry_account" {
  type      = "Microsoft.CognitiveServices/accounts@2026-03-01"
  parent_id = var.resource_group_id
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

  tags = var.tags

  schema_validation_enabled = false
  response_export_values    = ["identity.principalId", "properties.endpoint"]

  depends_on = [
    azapi_resource_action.purge_on_destroy,
  ]
}

# Without networkInjections the account reaches Succeeded quickly, but a short
# wait still lets the system-assigned identity propagate before downstream RBAC
# and connection creates run.
resource "time_sleep" "wait_account_ready" {
  depends_on      = [azapi_resource.foundry_account]
  create_duration = "60s"
}

resource "azurerm_role_assignment" "foundry_user" {
  for_each = { for u in var.foundry_users : u.object_id => u }

  scope              = azapi_resource.foundry_account.id
  role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/${local.foundry_user_role_id}"
  principal_id       = each.value.object_id
  principal_type     = each.value.principal_type

  depends_on = [time_sleep.wait_account_ready]
}

# Account SMI needs WRITE access to KV secrets, not just read. Once a BYO KV is
# attached, every subsequent connection that has a credential (e.g. App Insights
# with authType=ApiKey) gets its credential stored in the BYO KV — the account
# SMI is what writes those secrets. Read-only (Secrets User) is enough for AAD
# connections but fails the moment any non-AAD connection is added.
resource "azurerm_role_assignment" "account_kv_secrets_officer" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azapi_resource.foundry_account.output.identity.principalId

  depends_on = [time_sleep.wait_account_ready]
}

# The AI Search service's system-assigned identity performs integrated
# vectorization: when a file is uploaded to a knowledge source, Search calls
# this account's embedding deployment (text-embedding-3-large) through the
# azureOpenAI vectorizer. Because the account sets disableLocalAuth = true, that
# call must authenticate with Entra ID, so the Search SMI needs Cognitive
# Services OpenAI User on the account. Without it, ingestion fails at the
# embedding step. This is the search -> embedding hop, distinct from the
# project -> search grants in the foundry-project module.
resource "azurerm_role_assignment" "search_openai_user" {
  scope                = azapi_resource.foundry_account.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = var.ai_search_identity_principal_id
  principal_type       = "ServicePrincipal"

  depends_on = [time_sleep.wait_account_ready]
}

# Model deployments ------------------------------------------------------------

resource "azapi_resource" "gpt4o" {
  type      = "Microsoft.CognitiveServices/accounts/deployments@2026-03-01"
  parent_id = azapi_resource.foundry_account.id
  name      = "gpt-4o"

  body = {
    sku = {
      name     = var.gpt4o_sku_name
      capacity = var.gpt4o_capacity
    }
    properties = {
      model = merge(
        {
          format = "OpenAI"
          name   = "gpt-4o"
        },
        var.gpt4o_model_version == null ? {} : { version = var.gpt4o_model_version }
      )
    }
  }

  schema_validation_enabled = false
  response_export_values    = ["properties.model", "sku"]

  depends_on = [time_sleep.wait_account_ready]
}

resource "azapi_resource" "text_embedding_3_large" {
  type      = "Microsoft.CognitiveServices/accounts/deployments@2026-03-01"
  parent_id = azapi_resource.foundry_account.id
  name      = "text-embedding-3-large"

  body = {
    sku = {
      name     = var.embedding_sku_name
      capacity = var.embedding_capacity
    }
    properties = {
      model = merge(
        {
          format = "OpenAI"
          name   = "text-embedding-3-large"
        },
        var.embedding_model_version == null ? {} : { version = var.embedding_model_version }
      )
    }
  }

  schema_validation_enabled = false
  response_export_values    = ["properties.model", "sku"]

  # Serialize deployment creates to avoid 409 conflicts on the account.
  depends_on = [azapi_resource.gpt4o]
}

# Account-scoped connections ---------------------------------------------------
# Defined on the account so every project on this account inherits them by name.
# The project capability host references these by name; per Microsoft docs there
# is no implicit inheritance of capability host config, only of the connections
# themselves.

# BYO Key Vault connection MUST be the first connection on the account. The
# Foundry account RP rejects attaching a BYO KV ("switching key vault") once
# any other connection exists, because their secrets are bound to the account's
# managed KV. Sequence: account ready -> KV connection -> all other connections.
resource "azapi_resource" "conn_key_vault" {
  type      = "Microsoft.CognitiveServices/accounts/connections@2026-03-01"
  parent_id = azapi_resource.foundry_account.id
  name      = var.key_vault_name

  body = {
    properties = {
      category      = "AzureKeyVault"
      target        = var.key_vault_id
      authType      = "AccountManagedIdentity"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.key_vault_id
        location   = var.location
      }
    }
  }

  schema_validation_enabled = false

  depends_on = [
    azurerm_role_assignment.account_kv_secrets_officer,
  ]
}

resource "azapi_resource" "conn_cosmos" {
  type      = "Microsoft.CognitiveServices/accounts/connections@2026-03-01"
  parent_id = azapi_resource.foundry_account.id
  name      = var.cosmos_account_name

  body = {
    properties = {
      category      = "CosmosDb"
      target        = var.cosmos_account_endpoint
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.cosmos_account_id
        location   = var.location
      }
    }
  }

  schema_validation_enabled = false

  depends_on = [azapi_resource.conn_key_vault]
}

resource "azapi_resource" "conn_storage" {
  type      = "Microsoft.CognitiveServices/accounts/connections@2026-03-01"
  parent_id = azapi_resource.foundry_account.id
  name      = var.storage_account_name

  body = {
    properties = {
      category      = "AzureStorageAccount"
      target        = var.storage_blob_endpoint
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.storage_account_id
        location   = var.location
      }
    }
  }

  schema_validation_enabled = false

  depends_on = [azapi_resource.conn_key_vault]
}

resource "azapi_resource" "conn_search" {
  type      = "Microsoft.CognitiveServices/accounts/connections@2026-03-01"
  parent_id = azapi_resource.foundry_account.id
  name      = var.ai_search_name

  body = {
    properties = {
      category      = "CognitiveSearch"
      target        = "https://${var.ai_search_name}.search.windows.net"
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure"
        ApiVersion = "2025-05-01-preview"
        ResourceId = var.ai_search_id
        location   = var.location
      }
    }
  }

  schema_validation_enabled = false

  depends_on = [azapi_resource.conn_key_vault]
}

resource "azapi_resource" "conn_app_insights" {
  type      = "Microsoft.CognitiveServices/accounts/connections@2026-03-01"
  parent_id = azapi_resource.foundry_account.id
  name      = var.app_insights_name

  body = {
    properties = {
      category      = "AppInsights"
      target        = var.app_insights_id
      authType      = "ApiKey"
      isSharedToAll = true
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

  depends_on = [azapi_resource.conn_key_vault]
}

# Account-level capability host ------------------------------------------------
# Empty body — just declares the account participates in Agent Service. Docs say
# a project capability host can't be created until the account one exists.

resource "azapi_resource" "account_capability_host" {
  type      = "Microsoft.CognitiveServices/accounts/capabilityHosts@2025-04-01-preview"
  parent_id = azapi_resource.foundry_account.id
  name      = "caphost-${var.base_name}"

  body = {
    properties = {
      capabilityHostKind = "Agents"
    }
  }

  schema_validation_enabled = false

  depends_on = [
    azapi_resource.conn_cosmos,
    azapi_resource.conn_storage,
    azapi_resource.conn_search,
    azapi_resource.conn_key_vault,
    azapi_resource.conn_app_insights,
  ]
}

# Destroy-time purge -----------------------------------------------------------
# Cognitive Services accounts soft-delete; the deleted record reserves the name
# until purged.

resource "time_sleep" "purge_cooldown" {
  destroy_duration = "60s"

  triggers = {
    account_name = local.account_name
  }
}

resource "azapi_resource_action" "purge_on_destroy" {
  type        = "Microsoft.CognitiveServices/locations/resourceGroups/deletedAccounts@2025-06-01"
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.CognitiveServices/locations/${var.location}/resourceGroups/${var.resource_group_name}/deletedAccounts/${local.account_name}"
  method      = "DELETE"
  when        = "destroy"

  depends_on = [time_sleep.purge_cooldown]
}
