terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.38.0"
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

#region Basic AKS setup
# resource group for aks
resource "azurerm_resource_group" "aks_rg" {
  name     = "rg-chdemo-dev01"
  location = "eastus"
}

# vnet for aks
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "vnet_chdemo_dev01"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  address_space       = ["10.235.0.0/16"]
}

# subnet for aks
resource "azurerm_subnet" "aks_snet" {
  name                 = "snet-aks-chdemo-dev01"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.235.128.0/22"]
}

# refer to my team ad group to assign as aks admins 
data "azuread_group" "myteam" {
  display_name     = "sub_owners"
  security_enabled = true
}

# AKS user assigned identity
resource "azurerm_user_assigned_identity" "aks" {
  location            = azurerm_resource_group.aks_rg.location
  name                = "uai-aks-chdemo-dev01"
  resource_group_name = azurerm_resource_group.aks_rg.name
}

# Log analytics workspace for AKS and Application Insights
resource "azurerm_log_analytics_workspace" "instance_log" {
  name                = "log-chdemo-dev01"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  retention_in_days   = 30
}

# acr
resource "azurerm_container_registry" "acr" {
  name                = "acrchdemodev01"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  sku                 = "Standard"
  admin_enabled       = false
}

# aks cluster
resource "azurerm_kubernetes_cluster" "aks" {

  # any autoscaling should not be reset by TF after intial setup
  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }

  name                         = "aks-chdemo-dev01"
  kubernetes_version           = local.kubernetes_version
  location                     = azurerm_resource_group.aks_rg.location
  resource_group_name          = azurerm_resource_group.aks_rg.name
  dns_prefix                   = "aks-chdemo-dev01-dns"
  node_resource_group          = "rg-chdemo-aks-dev01"
  image_cleaner_enabled        = false
  image_cleaner_interval_hours = 48

  network_profile {
    network_plugin      = "azure"
    load_balancer_sku   = "standard"
    network_plugin_mode = "overlay"
    pod_cidr            = "100.112.0.0/12"
  }

  storage_profile {
    file_driver_enabled = true
  }

  default_node_pool {
    name                 = "chlinux"
    orchestrator_version = local.kubernetes_version
    node_count           = 1
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 4
    vm_size              = "Standard_B4ms"
    os_sku               = "Ubuntu"
    vnet_subnet_id       = azurerm_subnet.aks_snet.id
    max_pods             = 30
    type                 = "VirtualMachineScaleSets"
    scale_down_mode      = "Delete"
    zones                = ["1", "2", "3"]

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  #region promethus
  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }
  #endregion promethus

  timeouts {
    update = "180m"
    delete = "180m"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = false
    tenant_id          = local.tenant_id

    # add my team as cluster admin 
    admin_group_object_ids = [
    data.azuread_group.myteam.object_id] # azure AD group object ID

  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.instance_log.id
  }

}

resource "azurerm_role_assignment" "acr_attach" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
#endregion Basic AKS setup

#region Managed Prometheus setup
# Refer https://learn.microsoft.com/en-us/azure/azure-monitor/containers/kubernetes-monitoring-enable?tabs=terraform
# Azure monitor workspace
resource "azurerm_monitor_workspace" "instance_amw" {
  name                = "amw-chdemo-dev01"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
}

resource "azurerm_monitor_data_collection_endpoint" "dce" {
  name                = substr("MSProm-${azurerm_resource_group.aks_rg.location}-${azurerm_kubernetes_cluster.aks.name}", 0, min(44, length("MSProm-${azurerm_resource_group.aks_rg.location}-${azurerm_kubernetes_cluster.aks.name}")))
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  kind                = "Linux"
}

resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                        = substr("MSProm-${azurerm_resource_group.aks_rg.location}-${azurerm_kubernetes_cluster.aks.name}", 0, min(64, length("MSProm-${azurerm_resource_group.aks_rg.location}-${azurerm_kubernetes_cluster.aks.name}")))
  resource_group_name         = azurerm_resource_group.aks_rg.name
  location                    = azurerm_resource_group.aks_rg.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id
  kind                        = "Linux"

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.instance_amw.id
      name               = "MonitoringAccount1"
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = ["MonitoringAccount1"]
  }

  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }

  description = "DCR for Azure Monitor Metrics Profile (Managed Prometheus)"
  depends_on = [
    azurerm_monitor_data_collection_endpoint.dce
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "dcra" {
  name                    = "MSProm-${azurerm_resource_group.aks_rg.location}-${azurerm_kubernetes_cluster.aks.name}"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
  description             = "Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster."
  depends_on = [
    azurerm_monitor_data_collection_rule.dcr
  ]
}
#endregion Managed Prometheus setup