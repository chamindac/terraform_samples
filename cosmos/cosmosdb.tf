# resource "azurerm_cosmosdb_account" "instancecosmos" {
#   name                              = "${var.prefix}-${var.PROJECT}-${var.ENVNAME}-cdb"
#   location                          = azurerm_resource_group.instancerg.location
#   resource_group_name               = azurerm_resource_group.instancerg.name
#   offer_type                        = "Standard"
#   kind                              = "GlobalDocumentDB"
#   automatic_failover_enabled        = false
#   public_network_access_enabled     = true
#   ip_range_filter                   = "104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26,193.91.207.187,84.208.135.170,51.105.216.26,81.0.162.113${var.ENV == local.dev_environment ? ",${var.DEVELOPERIPS}" : ""}"
#   is_virtual_network_filter_enabled = true
#   default_identity_type             = "FirstPartyIdentity"

#   virtual_network_rule {
#     id = azurerm_subnet.aks.id
#   }

#   virtual_network_rule {
#     id = azurerm_subnet.subnet.id
#   }

#   virtual_network_rule {
#     id = var.AKS_BUILD_AGENT_SNET_ID
#   }

#   lifecycle {
#     prevent_destroy = true
#   }

#   geo_location {
#     location          = azurerm_resource_group.instancerg.location
#     failover_priority = 0
#   }

#   consistency_policy {
#     consistency_level       = "Session"
#     max_interval_in_seconds = 5
#     max_staleness_prefix    = 100
#   }

#   tags = merge(tomap({
#     Service              = "cosmosdb account"
#     SystemClassification = local.systemclassification_customerdata_tag
#   }), local.tags)
# }