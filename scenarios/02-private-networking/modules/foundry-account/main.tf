terraform {
  required_providers {
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

      publicNetworkAccess = "Disabled"
      networkAcls = {
        defaultAction = "Deny"
      }

      networkInjections = [
        {
          scenario                   = "agent"
          subnetArmId                = var.agent_subnet_id
          useMicrosoftManagedNetwork = false
        }
      ]
    }
  }

  tags = var.tags

  schema_validation_enabled = false
  response_export_values    = ["identity.principalId", "properties.endpoint"]

  depends_on = [
    azapi_resource_action.purge_on_destroy,
  ]
}

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

# Cooldown gives the Foundry control plane time to release the agent subnet's
# serviceAssociationLink before the subnet itself is deleted.
resource "time_sleep" "purge_cooldown" {
  destroy_duration = "900s"

  triggers = {
    account_name = local.account_name
  }
}

# Destroy-time purge of the soft-deleted account. Without this the agent subnet
# can't be deleted (InUseSubnetCannotBeDeleted) and the account name stays
# reserved. Matches the API/type pair Microsoft uses in their reference sample.
resource "azapi_resource_action" "purge_on_destroy" {
  type        = "Microsoft.Resources/resourceGroups/deletedAccounts@2021-04-30"
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.CognitiveServices/locations/${var.location}/resourceGroups/${var.resource_group_name}/deletedAccounts/${local.account_name}"
  method      = "DELETE"
  when        = "destroy"

  depends_on = [time_sleep.purge_cooldown]
}
