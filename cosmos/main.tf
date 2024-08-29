terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.116.0"
      # version = "=4.0.1"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "instance_rg" {
  name     = "ch-cosmostest-dev-wus-001-rg"
  location = "westus"
}

resource "azurerm_cosmosdb_account" "instancecosmos" {
  name                          = "ch-cosmostest-dev-wus-001-cdb"
  location                      = azurerm_resource_group.instance_rg.location
  resource_group_name           = azurerm_resource_group.instance_rg.name
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  automatic_failover_enabled    = false
  public_network_access_enabled = true
  # # For azurerm 4.0.1, comment line 10  and uncomment line 11
  # ip_range_filter = "46.15.109.71,104.42.195.92"
  # # ip_range_filter                   = ["46.15.109.71/32","104.42.195.92/32"]
  default_identity_type = "FirstPartyIdentity"

  geo_location {
    location          = azurerm_resource_group.instance_rg.location
    failover_priority = 0
  }

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }
}