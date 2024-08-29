resource "azurerm_cosmosdb_account" "instancecosmos" {
  name                              = "${var.prefix}-${var.project}-${var.env_name}-cdb"
  location                          = azurerm_resource_group.instance_rg.location
  resource_group_name               = azurerm_resource_group.instance_rg.name
  offer_type                        = "Standard"
  kind                              = "GlobalDocumentDB"
  automatic_failover_enabled        = false
  public_network_access_enabled     = true
  ip_range_filter                   = "46.15.109.71,104.42.195.92"
  is_virtual_network_filter_enabled = true
  default_identity_type             = "FirstPartyIdentity"

  virtual_network_rule {
    id = azurerm_subnet.aks.id
  }

  virtual_network_rule {
    id = azurerm_subnet.subnet.id
  }

  lifecycle {
    prevent_destroy = true
  }

  geo_location {
    location          = azurerm_resource_group.instance_rg.location
    failover_priority = 0
  }

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  tags = merge(tomap({
    Service = "cosmosdb account"
  }), local.tags)
}

# resource "azurerm_cosmosdb_sql_database" "instancecosmosorders" {
#   name                = "orders"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name

#   lifecycle {
#     prevent_destroy = true
#   }
# }
# resource "azurerm_cosmosdb_sql_container" "instancecosmosordersinfo" {
#   name                = "info"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name
#   database_name       = azurerm_cosmosdb_sql_database.instancecosmosorders.name
#   partition_key_paths = ["/partition"]

#   autoscale_settings {
#     max_throughput = 6000
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "azurerm_cosmosdb_sql_container" "instancecosmosorderscreatedstates" {
#   name                = "created-states"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name
#   database_name       = azurerm_cosmosdb_sql_database.instancecosmosorders.name
#   partition_key_paths = ["/partition"]
#   default_ttl         = 604800

#   autoscale_settings {
#     max_throughput = 4000
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }
# resource "azurerm_cosmosdb_sql_container" "instancecosmosordersprocessedstates" {
#   name                = "processed-states"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name
#   database_name       = azurerm_cosmosdb_sql_database.instancecosmosorders.name
#   partition_key_paths = ["/partition"]
#   default_ttl         = 604800

#   autoscale_settings {
#     max_throughput = 4000
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "azurerm_cosmosdb_sql_database" "instancecosmosbackgroundtasks" {
#   name                = "background-tasks"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name

#   lifecycle {
#     prevent_destroy = true
#   }
# }
# resource "azurerm_cosmosdb_sql_container" "instancecosmosbackgroundtasksserviceregistrations" {
#   name                = "service-registrations"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name
#   database_name       = azurerm_cosmosdb_sql_database.instancecosmosbackgroundtasks.name
#   partition_key_paths = ["/partition"]

#   autoscale_settings {
#     max_throughput = 4000
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }
# resource "azurerm_cosmosdb_sql_container" "instancecosmosbackgroundtaskssubtasks" {
#   name                = "sub-tasks"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name
#   database_name       = azurerm_cosmosdb_sql_database.instancecosmosbackgroundtasks.name
#   partition_key_paths = ["/partition"]
#   default_ttl         = 172800

#   autoscale_settings {
#     max_throughput = 6000
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }
# resource "azurerm_cosmosdb_sql_container" "instancecosmosbackgroundtaskstasks" {
#   name                = "tasks"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name
#   database_name       = azurerm_cosmosdb_sql_database.instancecosmosbackgroundtasks.name
#   partition_key_paths = ["/partition"]
#   default_ttl         = 172800

#   autoscale_settings {
#     max_throughput = 4000
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "azurerm_cosmosdb_sql_database" "instancecosmoscollections" {
#   name                = "collections"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name

#   lifecycle {
#     prevent_destroy = true
#   }
# }
# resource "azurerm_cosmosdb_sql_container" "instancecosmoscollectionsinvoices" {
#   name                = "invoices"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name
#   database_name       = azurerm_cosmosdb_sql_database.instancecosmoscollections.name
#   partition_key_paths = ["/partition"]

#   autoscale_settings {
#     max_throughput = 4000
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "azurerm_cosmosdb_sql_database" "instancecosmosconfig" {
#   name                = "config"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name

#   lifecycle {
#     prevent_destroy = true
#   }
# }
# resource "azurerm_cosmosdb_sql_container" "instancecosmosconfigformat" {
#   name                = "format"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name
#   database_name       = azurerm_cosmosdb_sql_database.instancecosmosconfig.name
#   partition_key_paths = ["/partition"]

#   autoscale_settings {
#     max_throughput = 4000
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }

# resource "azurerm_cosmosdb_sql_database" "instancecosmosbookings" {
#   name                = "bookings"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name

#   lifecycle {
#     prevent_destroy = true
#   }
# }
# resource "azurerm_cosmosdb_sql_container" "instancecosmosbookingsinfo" {
#   name                = "info"
#   resource_group_name = azurerm_resource_group.instance_rg.name
#   account_name        = azurerm_cosmosdb_account.instancecosmos.name
#   database_name       = azurerm_cosmosdb_sql_database.instancecosmosbookings.name
#   partition_key_paths = ["/partition"]

#   autoscale_settings {
#     max_throughput = 4000
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }
