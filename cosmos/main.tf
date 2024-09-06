terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # version = "=3.116.0"
      # version = "=4.0.1" # no smooth migration
      version = "=4.1.0" # Migrates fine
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "subscriptionid"
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
  # ip_range_filter               = "89.8.134.232,104.42.195.92"
  ip_range_filter       = ["89.8.134.232", "104.42.195.92"]
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

resource "azurerm_cosmosdb_sql_database" "instancecosmosorders" {
  name                = "orders"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name

  lifecycle {
    prevent_destroy = true
  }
}
resource "azurerm_cosmosdb_sql_container" "instancecosmosordersinfo" {
  name                = "info"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name
  database_name       = azurerm_cosmosdb_sql_database.instancecosmosorders.name
  partition_key_paths = ["/partition"]

  autoscale_settings {
    max_throughput = 6000
  }

  lifecycle {
    prevent_destroy = true
  }
}
resource "azurerm_cosmosdb_sql_container" "instancecosmosordersprocessstates" {
  name                = "process-states"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name
  database_name       = azurerm_cosmosdb_sql_database.instancecosmosorders.name
  partition_key_paths = ["/partition"]
  default_ttl         = 604800

  autoscale_settings {
    max_throughput = 4000
  }

  lifecycle {
    prevent_destroy = true
  }
}
resource "azurerm_cosmosdb_sql_container" "instancecosmosorderspaidstates" {
  name                = "paid-states"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name
  database_name       = azurerm_cosmosdb_sql_database.instancecosmosorders.name
  partition_key_paths = ["/partition"]
  default_ttl         = 604800

  autoscale_settings {
    max_throughput = 4000
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cosmosdb_sql_database" "instancecosmosbackgroundtasks" {
  name                = "background-tasks"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name

  lifecycle {
    prevent_destroy = true
  }
}
resource "azurerm_cosmosdb_sql_container" "instancecosmosbackgroundtasksserviceregistrations" {
  name                = "service-registrations"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name
  database_name       = azurerm_cosmosdb_sql_database.instancecosmosbackgroundtasks.name
  partition_key_paths = ["/partition"]

  autoscale_settings {
    max_throughput = 4000
  }

  lifecycle {
    prevent_destroy = true
  }
}
resource "azurerm_cosmosdb_sql_container" "instancecosmosbackgroundtaskssubtasks" {
  name                = "sub-tasks"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name
  database_name       = azurerm_cosmosdb_sql_database.instancecosmosbackgroundtasks.name
  partition_key_paths = ["/partition"]
  default_ttl         = 172800

  autoscale_settings {
    max_throughput = 6000
  }

  lifecycle {
    prevent_destroy = true
  }
}
resource "azurerm_cosmosdb_sql_container" "instancecosmosbackgroundtaskstasks" {
  name                = "tasks"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name
  database_name       = azurerm_cosmosdb_sql_database.instancecosmosbackgroundtasks.name
  partition_key_paths = ["/partition"]
  default_ttl         = 172800

  autoscale_settings {
    max_throughput = 4000
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cosmosdb_sql_database" "instancecosmoscollections" {
  name                = "collections"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name

  lifecycle {
    prevent_destroy = true
  }
}
resource "azurerm_cosmosdb_sql_container" "instancecosmoscollectionsinvoices" {
  name                = "invoices"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name
  database_name       = azurerm_cosmosdb_sql_database.instancecosmoscollections.name
  partition_key_paths = ["/partition"]

  autoscale_settings {
    max_throughput = 4000
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cosmosdb_sql_database" "instancecosmosconfig" {
  name                = "config"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name

  lifecycle {
    prevent_destroy = true
  }
}
resource "azurerm_cosmosdb_sql_container" "instancecosmosconfigpayment" {
  name                = "payment"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name
  database_name       = azurerm_cosmosdb_sql_database.instancecosmosconfig.name
  partition_key_paths = ["/partition"]

  autoscale_settings {
    max_throughput = 4000
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cosmosdb_sql_database" "instancecosmosfolders" {
  name                = "folders"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name

  lifecycle {
    prevent_destroy = true
  }
}
resource "azurerm_cosmosdb_sql_container" "instancecosmosfoldersinfo" {
  name                = "info"
  resource_group_name = azurerm_resource_group.instance_rg.name
  account_name        = azurerm_cosmosdb_account.instancecosmos.name
  database_name       = azurerm_cosmosdb_sql_database.instancecosmosfolders.name
  partition_key_paths = ["/partition"]

  autoscale_settings {
    max_throughput = 4000
  }

  lifecycle {
    prevent_destroy = true
  }
}