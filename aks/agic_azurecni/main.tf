locals {
  kubernetes_version = "1.24.9"
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.44.1"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=2.34.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# resource group for aks
resource "azurerm_resource_group" "aks_rg" {
  name     = "rg-chdemo-dev04"
  location = "westeurope"
}

# vnet for aks
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "vnet_chdemo_dev04"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  address_space       = ["10.235.0.0/16"]
}

# subnet for aks
resource "azurerm_subnet" "aks_snet" {
  name                 = "snet-aks-chdemo-dev04"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.235.128.0/18"]
}

# subnet for aks ingress agw
resource "azurerm_subnet" "aks_agw_snet" {
  name                 = "snet-agw-chdemo-dev04"
  resource_group_name  = azurerm_resource_group.aks_rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.235.0.0/24"]
}

# public ip for aks ingress agw
resource "azurerm_public_ip" "aks_agw_pip" {
  name                = "pip-chdemo-dev04"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  
}

# ingress agw for aks 
resource "azurerm_application_gateway" "aks_agw" {
  name                = "agw-chdemo-dev04"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 0
    max_capacity = 10
  }

  gateway_ip_configuration {
    name      = "agwIpConfig"
    subnet_id = azurerm_subnet.aks_agw_snet.id

  }
  
  frontend_port {
    name = "port_80"
    port = 80
  }

  # need to have a public IP for Standard_v2 AGW. will not be used with any listerners by AKS
  frontend_ip_configuration {
    name                 = "chdemoAKSPublicFrontendIp"
    public_ip_address_id = azurerm_public_ip.aks_agw_pip.id
  }

  frontend_ip_configuration {
    name                 = "chdemoAKSPrivateFrontendIp"
    private_ip_address   = "10.235.0.100"
    private_ip_address_allocation = "Static"
    subnet_id = azurerm_subnet.aks_agw_snet.id
  }

  # dummy intial configuration for backend, listners, rules
  # in agw is required to set it up
  backend_address_pool {
    name = "dummyBackend"
  }

  backend_http_settings {
    name                  = "dummyBackendSettings"
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "dummyListener"
    frontend_ip_configuration_name = "chdemoAKSPrivateFrontendIp"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "dummyRule"
    rule_type                  = "Basic"
    http_listener_name         = "dummyListener"
    backend_address_pool_name  = "dummyBackend"
    backend_http_settings_name = "dummyBackendSettings"
    priority                   = 100
  }

  # after we hand over the control to aks cluster to
  # manage configurations for aks ingress in the agw
  # we have to prevent update via terraform to below configurations in agw
  # tags is not madatory to ignore but nice to have
  lifecycle {
    ignore_changes       = [
      backend_address_pool, 
      backend_http_settings,
      http_listener,
      probe,
      request_routing_rule,
      url_path_map,
      rewrite_rule_set,
      frontend_port,
      tags
    ]
  }
}

# acr
resource "azurerm_container_registry" "acr" {
  name                = "acrchdemodev04"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  sku                 = "Standard"
  admin_enabled       = false
}

# refer to my team ad group to assign as aks admins 
data "azuread_group" "myteam" {
  display_name     = "sub_owners"
  security_enabled = true
}

# aks cluster
resource "azurerm_kubernetes_cluster" "aks" {

  # any autoscaling should not be reset by TF after intial setup
  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }

  name                = "aks-chdemo-dev04"
  kubernetes_version  = local.kubernetes_version
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "aks-chdemo-dev04-dns"
  node_resource_group = "rg-chdemo-aks-dev04"

  network_profile {
    network_plugin = "azure"
  }

  default_node_pool {
    name                  = "demo04linux"
    orchestrator_version  = local.kubernetes_version
    enable_auto_scaling   = true
    node_count            = 1
    min_count             = 1
    max_count             = 5
    max_pods              = 110
    vm_size               = "Standard_B4ms"
    vnet_subnet_id        = azurerm_subnet.aks_snet.id
  }

  identity {
    type = "SystemAssigned"
  }

  windows_profile {
    admin_username = "nodeadmin"
    admin_password = "AdminPasswd@001"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.aks_agw.id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = false
    managed                = true
    tenant_id              = "efbad420-a8aa-4fcc-9e95-1d06435672d9"

    # add my team as cluster admin 
    admin_group_object_ids =  [
            data.azuread_group.myteam.object_id] # azure AD group object ID

  }

}

# windows node pool for aks
resource "azurerm_kubernetes_cluster_node_pool" "aks_win" {
  
  lifecycle {
    ignore_changes = [node_count]
  }

  name                  = "win04"
  orchestrator_version  = local.kubernetes_version
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  enable_auto_scaling   = true
  node_count            = 1
  min_count             = 1
  max_count             = 20
  max_pods              = 30
  vm_size               = "Standard_B4ms"
  os_type               = "Windows"
  vnet_subnet_id        = azurerm_subnet.aks_snet.id
  os_disk_size_gb       = "512"
  scale_down_mode       = "Delete"

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
  
}

resource "azurerm_role_assignment" "acr_attach" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

#---------------------
# Ingess agw for aks is not getting the managed identity assigned automatically when attached with TF
# need to get the user assigned managed id from node rg when it is available after cluster creation

# get node rg
data "azurerm_resource_group" "aks_node_rg" {
  name     = "rg-chdemo-aks-dev04"
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}

# get user assigned manged id
data "azurerm_user_assigned_identity" "aks_agw_uid" {
  resource_group_name = data.azurerm_resource_group.aks_node_rg.name
  name = "ingressapplicationgateway-${azurerm_kubernetes_cluster.aks.name}"

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    data.azurerm_resource_group.aks_node_rg
  ]
}

# assign user assigned managed id of aks to ingress agw - required to allow AGIC to manage agw
resource "azurerm_role_assignment" "aks_agw_role" {
  principal_id                     = data.azurerm_user_assigned_identity.aks_agw_uid.principal_id
  role_definition_name             = "Contributor"
  scope                            = azurerm_application_gateway.aks_agw.id
  
  depends_on = [
    azurerm_kubernetes_cluster.aks,
    data.azurerm_resource_group.aks_node_rg,
    data.azurerm_user_assigned_identity.aks_agw_uid
  ]
}
