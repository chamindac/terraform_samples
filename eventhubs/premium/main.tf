terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.16.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=3.1.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "subscription"
}

resource "azurerm_resource_group" "instance_rg" {
  name     = "ch-eh-dev-eus-001-rg"
  location = "eastus"
}

resource "azurerm_storage_account" "instancestorageehn" {
  name                             = "chehdeveus001ehn"
  location                         = azurerm_resource_group.instance_rg.location
  resource_group_name              = azurerm_resource_group.instance_rg.name
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  account_kind                     = "StorageV2"
  access_tier                      = "Hot"
  allow_nested_items_to_be_public  = false
  min_tls_version                  = "TLS1_2"
  cross_tenant_replication_enabled = false  
}

resource "azurerm_eventhub_namespace" "instanceeventhub" {
  count                    = 2
  name                     = "ch-eh-dev-eus-001-${count.index + 1}"
  location                 = azurerm_resource_group.instance_rg.location
  resource_group_name      = azurerm_resource_group.instance_rg.name
  sku                      = "Standard"
  capacity                 = 1
  auto_inflate_enabled     = true
  maximum_throughput_units = 40
}

resource "azurerm_eventhub_namespace" "instanceeventhub_premium" {
  count                    = 1
  name                     = "ch-eh-dev-eus-001-${length(azurerm_eventhub_namespace.instanceeventhub) + count.index + 1}"
  location                 = azurerm_resource_group.instance_rg.location
  resource_group_name      = azurerm_resource_group.instance_rg.name
  sku                      = "Premium"
  capacity                 = 1
  auto_inflate_enabled     = false # true only for Standard
  maximum_throughput_units = 0 # value only for Standard

  depends_on = [ azurerm_eventhub_namespace.instanceeventhub ]
}

resource "azurerm_eventhub_namespace_authorization_rule" "consumer" {
  for_each = {
    eventhub1consumer = azurerm_eventhub_namespace.instanceeventhub[0].name
    eventhub2consumer = azurerm_eventhub_namespace.instanceeventhub[1].name
    eventhub3consumer = azurerm_eventhub_namespace.instanceeventhub_premium[0].name
  }
  name                = "consumer"
  namespace_name      = each.value
  resource_group_name = azurerm_resource_group.instance_rg.name

  listen = true
  send   = true
  manage = true

  lifecycle {
    ignore_changes = []
  }
}

resource "azurerm_eventhub_namespace_authorization_rule" "publisher" {
  for_each = {
    eventhub1publisher = azurerm_eventhub_namespace.instanceeventhub[0].name
    eventhub2publisher = azurerm_eventhub_namespace.instanceeventhub[1].name
    eventhub3publisher = azurerm_eventhub_namespace.instanceeventhub_premium[0].name
  }
  name                = "publisher"
  namespace_name      = each.value
  resource_group_name = azurerm_resource_group.instance_rg.name

  listen = true
  send   = true
  manage = true

  lifecycle {
    ignore_changes = []
  }
}

resource "azurerm_eventhub" "eventhub" {
  for_each = {
    neworder        = azurerm_eventhub_namespace.instanceeventhub[0].id
    cancelledorder  = azurerm_eventhub_namespace.instanceeventhub[0].id
    dispatchedorder = azurerm_eventhub_namespace.instanceeventhub[0].id
    approvedorder   = azurerm_eventhub_namespace.instanceeventhub[0].id
    newpayment      = azurerm_eventhub_namespace.instanceeventhub[0].id
    paidinvoice     = azurerm_eventhub_namespace.instanceeventhub[1].id
    approvedpayment = azurerm_eventhub_namespace.instanceeventhub[1].id
    newinvoice      = azurerm_eventhub_namespace.instanceeventhub[1].id
  }
  name              = each.key
  namespace_id      = each.value
  partition_count   = 10
  message_retention = 1

  lifecycle {
    ignore_changes = []
  }
}

resource "azurerm_eventhub" "eventhub_premium" {
  for_each = {
    neworder        = azurerm_eventhub_namespace.instanceeventhub_premium[0].id
    newpayment      = azurerm_eventhub_namespace.instanceeventhub_premium[0].id    
  }
  name              = each.key
  namespace_id      = each.value
  partition_count   = 100
  message_retention = 1

  lifecycle {
    ignore_changes = []
  }
}

resource "azurerm_eventhub_consumer_group" "consumer_group_0_0" {
  for_each = {
    "ch.demo.order.eventhandler"    = azurerm_eventhub.eventhub["neworder"].name
    "ch.demo.customer.eventhandler" = azurerm_eventhub.eventhub["neworder"].name
    "ch.demo.payment.eventhandler"  = azurerm_eventhub.eventhub["cancelledorder"].name
    "ordercleanup"                  = azurerm_eventhub.eventhub["cancelledorder"].name
  }
  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.instanceeventhub[0].name
  eventhub_name       = each.value
  resource_group_name = azurerm_resource_group.instance_rg.name

  lifecycle {
    ignore_changes = []
  }
}

resource "azurerm_eventhub_consumer_group" "consumer_group_0_1" {
  for_each = {
    "itemsupdate" = azurerm_eventhub.eventhub["dispatchedorder"].name
  }
  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.instanceeventhub[0].name
  eventhub_name       = each.value
  resource_group_name = azurerm_resource_group.instance_rg.name

  lifecycle {
    ignore_changes = []
  }
}

resource "azurerm_eventhub_consumer_group" "consumer_group_0_2" {
  for_each = {
    "ch.demo.order.eventhandler"       = azurerm_eventhub.eventhub["dispatchedorder"].name
    "ch.demo.order.items.eventhandler" = azurerm_eventhub.eventhub["dispatchedorder"].name
    "ch.demo.invoice.eventhandler"     = azurerm_eventhub.eventhub["dispatchedorder"].name
    "ch.demo.customer.eventhandler"    = azurerm_eventhub.eventhub["dispatchedorder"].name
    "ch.demo.payment.eventhandler"     = azurerm_eventhub.eventhub["dispatchedorder"].name
    "orderprocess"                     = azurerm_eventhub.eventhub["approvedorder"].name
    "itemsupdate"                      = azurerm_eventhub.eventhub["approvedorder"].name
  }
  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.instanceeventhub[0].name
  eventhub_name       = each.value
  resource_group_name = azurerm_resource_group.instance_rg.name

  lifecycle {
    ignore_changes = []
  }
}

resource "azurerm_eventhub_consumer_group" "consumer_group_0_3" {
  for_each = {
    "ch.demo.customer.eventhandler" = azurerm_eventhub.eventhub["newpayment"].name
    "ch.demo.payment.eventhandler"  = azurerm_eventhub.eventhub["newpayment"].name
  }
  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.instanceeventhub[0].name
  eventhub_name       = each.value
  resource_group_name = azurerm_resource_group.instance_rg.name

  lifecycle {
    ignore_changes = []
  }
}

resource "azurerm_eventhub_consumer_group" "consumer_group_1_0" {
  for_each = {
    "ch.demo.invoice.eventhandler"  = azurerm_eventhub.eventhub["paidinvoice"].name
    "ch.demo.payment.eventhandler"  = azurerm_eventhub.eventhub["approvedpayment"].name
    "ch.demo.customer.eventhandler" = azurerm_eventhub.eventhub["newinvoice"].name
  }
  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.instanceeventhub[1].name
  eventhub_name       = each.value
  resource_group_name = azurerm_resource_group.instance_rg.name

  lifecycle {
    ignore_changes = []
  }
}

resource "azurerm_eventhub_consumer_group" "consumer_group_1_1" {
  for_each = {
    "ch.demo.invoice.eventhandler"  = azurerm_eventhub.eventhub["newinvoice"].name
    "orderupdate"                   = azurerm_eventhub.eventhub["paidinvoice"].name
    "ch.demo.customer.eventhandler" = azurerm_eventhub.eventhub["paidinvoice"].name
  }
  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.instanceeventhub[1].name
  eventhub_name       = each.value
  resource_group_name = azurerm_resource_group.instance_rg.name

  lifecycle {
    ignore_changes = []
  }
}

resource "azurerm_eventhub_consumer_group" "consumer_group_2_0" {
  for_each = {
    "ch.demo.order.eventhandler"    = azurerm_eventhub.eventhub_premium["neworder"].name
    "ch.demo.customer.eventhandler" = azurerm_eventhub.eventhub_premium["neworder"].name
  }
  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.instanceeventhub_premium[0].name
  eventhub_name       = each.value
  resource_group_name = azurerm_resource_group.instance_rg.name

  lifecycle {
    ignore_changes = []
  }
}