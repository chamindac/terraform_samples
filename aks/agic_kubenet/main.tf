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
  name     = "c"
  location = "westeurope"
}

# aks cluster
resource "azurerm_kubernetes_cluster" "aks" {

  # any autoscaling should not be reset by TF after intial setup
  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }

  name                = "aks-kubenetdemo-dev01"
  kubernetes_version  = "1.23.8"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "aks-kubenetdemo-dev01-dns"
  

  network_profile {
    load_balancer_sku = "standard"
    network_plugin    = "kubenet"
  }

  default_node_pool {
    name                = "demo01linux"
    enable_auto_scaling = true
    node_count          = 1
    min_count           = 1
    max_count           = 5
    max_pods            = 110
    vm_size             = "Standard_B4ms"
  }

  identity {
    type = "SystemAssigned"
  }

  # this will deploy an app gatway in the same vnet
  # of the AKS cluster and apply user assigned identity
  # of the AKS cluster for AGIC to the app gateway
  # so that the app gateway configurations can be managed by the AGIC
  # based on AKS cluster ingress requirements
  ingress_application_gateway {
    gateway_name = "agw-aksingress-demo01"
    subnet_cidr = "10.225.0.0/24"
  }
}