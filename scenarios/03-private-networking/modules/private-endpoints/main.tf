terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

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
