terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

locals {
  dns_zone_names = {
    blob               = "privatelink.blob.core.windows.net"
    cosmos             = "privatelink.documents.azure.com"
    search             = "privatelink.search.windows.net"
    cognitive_services = "privatelink.cognitiveservices.azure.com"
    ai_services        = "privatelink.services.ai.azure.com"
    openai             = "privatelink.openai.azure.com"
  }
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.base_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "agent" {
  name                 = "snet-agent"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.agent_subnet_prefix]

  delegation {
    name = "Microsoft.App/environments"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "private_endpoint" {
  name                 = "snet-pe"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.private_endpoint_subnet_prefix]
}

resource "azurerm_private_dns_zone" "this" {
  for_each = local.dns_zone_names

  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = local.dns_zone_names

  name                  = "link-${each.key}-${var.base_name}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}
