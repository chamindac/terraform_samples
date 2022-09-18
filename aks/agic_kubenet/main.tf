terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.23.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# resource group for aks
resource "azurerm_resource_group" "aks_rg" {
  name     = "rg-aks-dev04"
  location = "westeurope"
}

# vnet for aks
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "vnet_aks_dev04"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  address_space       = ["10.0.0.0/16"]
}
