# One-shot state migration from azapi → azurerm for scenario 01.
#
# After a successful `terraform apply` against the existing state, delete this
# file (and remove `azapi` from providers.tf) in a follow-up commit.
#
# Mechanics:
#   - `removed` blocks drop the old `azapi_resource.*` addresses from state
#     without touching the underlying Azure resources.
#   - `import` blocks pull those same Azure resources into the new
#     `azurerm_*` addresses defined in main.tf.

removed {
  from = azapi_resource.foundry_account
  lifecycle {
    destroy = false
  }
}

removed {
  from = azapi_resource.foundry_project
  lifecycle {
    destroy = false
  }
}

removed {
  from = azapi_resource.gpt4o
  lifecycle {
    destroy = false
  }
}

import {
  to = azurerm_cognitive_account.this
  id = "${azurerm_resource_group.this.id}/providers/Microsoft.CognitiveServices/accounts/${local.account_name}"
}

import {
  to = azurerm_cognitive_account_project.this
  id = "${azurerm_resource_group.this.id}/providers/Microsoft.CognitiveServices/accounts/${local.account_name}/projects/${local.project_name}"
}

import {
  to = azurerm_cognitive_deployment.gpt4o
  id = "${azurerm_resource_group.this.id}/providers/Microsoft.CognitiveServices/accounts/${local.account_name}/deployments/gpt-4o"
}
