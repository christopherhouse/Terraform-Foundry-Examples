terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Private endpoint for the Foundry account. Lives in the AI RG (with the
# account), resolves through three DNS zones in the network RG —
# cognitiveservices, services.ai.azure.com, and openai — because the account
# exposes APIs under all three suffixes.

resource "azurerm_private_endpoint" "foundry" {
  name                = "pep-foundry-${var.base_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-foundry-${var.base_name}"
    private_connection_resource_id = var.foundry_account_id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      var.dns_zone_id_cognitive_services,
      var.dns_zone_id_ai_services,
      var.dns_zone_id_openai,
    ]
  }
}
