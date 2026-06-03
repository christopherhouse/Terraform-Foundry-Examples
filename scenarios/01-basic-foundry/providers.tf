terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # azapi is retained only for the one-shot `removed` blocks in
    # migrations.tf. Drop this (and the provider block below) once the
    # azapi → azurerm state migration has applied.
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "RG-TF"
    storage_account_name = "cmhtfstatesa"
    container_name       = "tfstate"
    key                  = "foundry-examples/01-basic-foundry.tfstate"
    use_oidc             = true
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
  use_oidc            = true
  storage_use_azuread = true
}

provider "azapi" {
  use_oidc = true
}
