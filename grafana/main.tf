locals {
  grafana_version = 11
  subscription_id = "subscription_id"
  tenant_id       = "tenant_id"
}

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.38.1"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=3.4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = local.subscription_id
}

data "azurerm_subscription" "current" {
}

resource "azurerm_resource_group" "instance_rg" {
  name     = "ch-demo-grafana-shared-rg"
  location = "eastus"
}

# refer to sub_owners ad group to assign as aks admins 
data "azuread_group" "sub_owners" {
  display_name     = "sub_owners"
  security_enabled = true
}

resource "azurerm_dashboard_grafana" "grafana" {
  name                              = "ch-demo-shared-dg-001"
  resource_group_name               = azurerm_resource_group.instance_rg.name
  location                          = azurerm_resource_group.instance_rg.location
  grafana_major_version             = local.grafana_version
  api_key_enabled                   = false
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true
  zone_redundancy_enabled           = false
  sku                               = "Standard"

  identity {
    type = "SystemAssigned"
  }
}

# Add grafana system assigned managed id as monitoring reader to subscription scope
resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  principal_id         = azurerm_dashboard_grafana.grafana.identity[0].principal_id
  role_definition_name = "Monitoring Reader"
  scope                = data.azurerm_subscription.current.id
}

# Add subscription owners as grafana admins
resource "azurerm_role_assignment" "grafana_admin_sub_owners" {
  principal_id         = data.azuread_group.sub_owners.object_id
  role_definition_name = "Grafana Admin"
  scope                = azurerm_dashboard_grafana.grafana.id
}