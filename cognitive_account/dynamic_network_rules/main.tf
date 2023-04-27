terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.53.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# resource group 
resource "azurerm_resource_group" "rg" {
  name     = "rg-cognitive-test01"
  location = "eastus"
}

# vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-cognitive-test01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.124.0.0/16"]
}

# subnet for aks
resource "azurerm_subnet" "aks_snet" {
  name                 = "snet-aks-cognitive-test01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.124.128.0/18"]
  service_endpoints    = ["Microsoft.CognitiveServices"]
}

# subnet for vms
resource "azurerm_subnet" "vm_snet" {
  name                 = "snet-vm-cognitive-test01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.124.0.0/24"]
  service_endpoints    = ["Microsoft.CognitiveServices"]
}

resource "azurerm_cognitive_account" "ca" {
  name                  = "cs-cognitive-test01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  kind                  = "TextTranslation"
  custom_subdomain_name = "cs-cognitive-test01"

  sku_name = "F0"

  network_acls {
    default_action = "Deny"

    virtual_network_rules {
      subnet_id = azurerm_subnet.vm_snet.id
    }

    dynamic "virtual_network_rules" {
      for_each = var.env == "dev" ? [1] : []
      content {
        subnet_id = azurerm_subnet.aks_snet.id
      }
    }
  }
}