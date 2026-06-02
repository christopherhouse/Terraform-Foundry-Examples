locals {
  region_short = {
    eastus        = "eus"
    eastus2       = "eus2"
    westus2       = "wus2"
    westus3       = "wus3"
    swedencentral = "swc"
    northeurope   = "neu"
    westeurope    = "weu"
  }
  region_abbr = lookup(local.region_short, var.location, var.location)

  base_name      = "${var.workload}-${var.scenario_id}-${var.environment}-${local.region_abbr}-${var.instance}"
  base_name_flat = lower(replace(local.base_name, "-", ""))

  rg_name = "rg-${local.base_name}"

  default_tags = {
    Workload    = var.workload
    Scenario    = var.scenario_id
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repo        = "christopherhouse/Terraform-Foundry-Examples"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "./modules/network"

  resource_group_name            = azurerm_resource_group.this.name
  location                       = var.location
  base_name                      = local.base_name
  vnet_address_space             = var.vnet_address_space
  agent_subnet_prefix            = var.agent_subnet_prefix
  private_endpoint_subnet_prefix = var.private_endpoint_subnet_prefix
  tags                           = local.tags
}

module "data_resources" {
  source = "./modules/data-resources"

  resource_group_name = azurerm_resource_group.this.name
  resource_group_id   = azurerm_resource_group.this.id
  location            = var.location
  base_name           = local.base_name
  base_name_flat      = local.base_name_flat
  tags                = local.tags
}

module "foundry_account" {
  source = "./modules/foundry-account"

  resource_group_id   = azurerm_resource_group.this.id
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  base_name           = local.base_name
  agent_subnet_id     = module.network.agent_subnet_id

  gpt4o_sku_name          = var.gpt4o_sku_name
  gpt4o_capacity          = var.gpt4o_capacity
  gpt4o_model_version     = var.gpt4o_model_version
  embedding_sku_name      = var.embedding_sku_name
  embedding_capacity      = var.embedding_capacity
  embedding_model_version = var.embedding_model_version

  tags = local.tags
}

module "private_endpoints" {
  source = "./modules/private-endpoints"

  resource_group_name        = azurerm_resource_group.this.name
  location                   = var.location
  base_name                  = local.base_name
  private_endpoint_subnet_id = module.network.private_endpoint_subnet_id

  storage_account_id = module.data_resources.storage_account_id
  cosmos_account_id  = module.data_resources.cosmos_account_id
  ai_search_id       = module.data_resources.ai_search_id
  foundry_account_id = module.foundry_account.account_id

  dns_zone_id_blob               = module.network.dns_zone_ids.blob
  dns_zone_id_cosmos             = module.network.dns_zone_ids.cosmos
  dns_zone_id_search             = module.network.dns_zone_ids.search
  dns_zone_id_cognitive_services = module.network.dns_zone_ids.cognitive_services
  dns_zone_id_ai_services        = module.network.dns_zone_ids.ai_services
  dns_zone_id_openai             = module.network.dns_zone_ids.openai

  tags = local.tags
}

module "foundry_project" {
  source = "./modules/foundry-project"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  base_name           = local.base_name
  environment         = var.environment

  foundry_account_id   = module.foundry_account.account_id
  foundry_account_name = module.foundry_account.account_name

  storage_account_id      = module.data_resources.storage_account_id
  storage_account_name    = module.data_resources.storage_account_name
  storage_blob_endpoint   = module.data_resources.storage_blob_endpoint
  cosmos_account_id       = module.data_resources.cosmos_account_id
  cosmos_account_name     = module.data_resources.cosmos_account_name
  cosmos_account_endpoint = module.data_resources.cosmos_account_endpoint
  ai_search_id            = module.data_resources.ai_search_id
  ai_search_name          = module.data_resources.ai_search_name

  tags = local.tags

  depends_on = [
    module.private_endpoints,
  ]
}
