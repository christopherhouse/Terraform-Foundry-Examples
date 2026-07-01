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

  # Lifecycle-driven RG split. Each RG holds resources that share the same
  # owner, deploy cadence, and blast radius. See README for the rationale.
  rg_name_net  = "rg-net-${local.base_name}"
  rg_name_data = "rg-data-${local.base_name}"
  rg_name_ai   = "rg-ai-${local.base_name}"
  rg_name_obs  = "rg-obs-${local.base_name}"

  default_tags = {
    Workload    = var.workload
    Scenario    = var.scenario_id
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repo        = "christopherhouse/Terraform-Foundry-Examples"
  }
  tags = merge(local.default_tags, var.tags)
}

# --- Resource groups ---------------------------------------------------------
# rg-net:  VNet, subnets, NSGs, private DNS zones — platform/network team
# rg-data: Storage, Cosmos, AI Search + their PEs — data platform team
# rg-ai:   Foundry account, model deployments, project, capability host,
#          + the account's PE — AI workload team
# rg-obs:  Log Analytics workspace + App Insights — platform/observability team

resource "azurerm_resource_group" "net" {
  name     = local.rg_name_net
  location = var.location
  tags     = merge(local.tags, { Tier = "network" })
}

resource "azurerm_resource_group" "data" {
  name     = local.rg_name_data
  location = var.location
  tags     = merge(local.tags, { Tier = "data" })
}

resource "azurerm_resource_group" "ai" {
  name     = local.rg_name_ai
  location = var.location
  tags     = merge(local.tags, { Tier = "ai-platform" })
}

resource "azurerm_resource_group" "obs" {
  name     = local.rg_name_obs
  location = var.location
  tags     = merge(local.tags, { Tier = "observability" })
}

# --- Network (rg-net) --------------------------------------------------------

module "network" {
  source = "./modules/network"

  resource_group_name            = azurerm_resource_group.net.name
  location                       = var.location
  base_name                      = local.base_name
  vnet_address_space             = var.vnet_address_space
  agent_subnet_prefix            = var.agent_subnet_prefix
  private_endpoint_subnet_prefix = var.private_endpoint_subnet_prefix
  tags                           = local.tags
}

# --- Data resources (rg-data) ------------------------------------------------

module "data_resources" {
  source = "./modules/data-resources"

  resource_group_name = azurerm_resource_group.data.name
  resource_group_id   = azurerm_resource_group.data.id
  location            = var.location
  base_name           = local.base_name
  base_name_flat      = local.base_name_flat
  tags                = local.tags
}

# --- Observability (rg-obs) --------------------------------------------------

module "observability" {
  source = "./modules/observability"

  resource_group_name = azurerm_resource_group.obs.name
  resource_group_id   = azurerm_resource_group.obs.id
  location            = var.location
  base_name           = local.base_name
  tags                = local.tags
}

module "data_private_endpoints" {
  source = "./modules/data-private-endpoints"

  resource_group_name        = azurerm_resource_group.data.name
  location                   = var.location
  base_name                  = local.base_name
  private_endpoint_subnet_id = module.network.private_endpoint_subnet_id

  storage_account_id = module.data_resources.storage_account_id
  cosmos_account_id  = module.data_resources.cosmos_account_id
  ai_search_id       = module.data_resources.ai_search_id

  dns_zone_id_blob   = module.network.dns_zone_ids.blob
  dns_zone_id_cosmos = module.network.dns_zone_ids.cosmos
  dns_zone_id_search = module.network.dns_zone_ids.search

  tags = local.tags
}

# --- AI platform (rg-ai) -----------------------------------------------------

module "foundry_account" {
  source = "./modules/foundry-account"

  resource_group_id   = azurerm_resource_group.ai.id
  resource_group_name = azurerm_resource_group.ai.name
  location            = var.location
  base_name           = local.base_name
  agent_subnet_id     = module.network.agent_subnet_id

  gpt4o_sku_name          = var.gpt4o_sku_name
  gpt4o_capacity          = var.gpt4o_capacity
  gpt4o_model_version     = var.gpt4o_model_version
  embedding_sku_name      = var.embedding_sku_name
  embedding_capacity      = var.embedding_capacity
  embedding_model_version = var.embedding_model_version

  ai_search_identity_principal_id = module.data_resources.ai_search_identity_principal_id

  foundry_users = var.foundry_users

  tags = local.tags
}

module "foundry_private_endpoint" {
  source = "./modules/foundry-private-endpoint"

  resource_group_name        = azurerm_resource_group.ai.name
  location                   = var.location
  base_name                  = local.base_name
  private_endpoint_subnet_id = module.network.private_endpoint_subnet_id

  foundry_account_id = module.foundry_account.account_id

  dns_zone_id_cognitive_services = module.network.dns_zone_ids.cognitive_services
  dns_zone_id_ai_services        = module.network.dns_zone_ids.ai_services
  dns_zone_id_openai             = module.network.dns_zone_ids.openai

  tags = local.tags
}

module "foundry_project" {
  source = "./modules/foundry-project"

  # The project is an ARM child of the account, so it inherits rg-ai
  # implicitly via parent_id. The only RG name the module still needs is
  # the Cosmos account's RG (rg-data here), because
  # azurerm_cosmosdb_sql_role_assignment looks up the account by
  # (RG name, account name) rather than by scope.
  cosmos_resource_group_name = azurerm_resource_group.data.name
  location                   = var.location
  base_name                  = local.base_name
  environment                = var.environment

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

  app_insights_id                = module.observability.app_insights_id
  app_insights_name              = module.observability.app_insights_name
  app_insights_connection_string = module.observability.app_insights_connection_string

  tags = local.tags

  depends_on = [
    module.data_private_endpoints,
    module.foundry_private_endpoint,
  ]
}
