terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Private endpoints for the BYO data resources. These live in the data RG
# (with their target resources), but resolve through DNS zones in the network
# RG — the zone group writes A-records cross-RG.

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pep-blob-${var.base_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-blob-${var.base_name}"
    private_connection_resource_id = var.storage_account_id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.dns_zone_id_blob]
  }
}

resource "azurerm_private_endpoint" "cosmos" {
  name                = "pep-cosmos-${var.base_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-cosmos-${var.base_name}"
    private_connection_resource_id = var.cosmos_account_id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.dns_zone_id_cosmos]
  }
}

resource "azurerm_private_endpoint" "search" {
  name                = "pep-search-${var.base_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-search-${var.base_name}"
    private_connection_resource_id = var.ai_search_id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.dns_zone_id_search]
  }
}
