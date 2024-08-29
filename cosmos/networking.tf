data "http" "mytfip" {
  url = "https://api.ipify.org" # http://ipv4.icanhazip.com
}

# vnet
resource "azurerm_virtual_network" "env_vnet" {
  name                = "${var.prefix}-${var.project}-${var.env_name}-vnet"
  resource_group_name = azurerm_resource_group.instance_rg.name
  location            = azurerm_resource_group.instance_rg.location
  address_space       = [var.vnet_cidr]
}

# AKS nsg
resource "azurerm_network_security_group" "aks" {
  name                = "${var.prefix}-${var.project}-${var.env_name}-aks-nsg"
  location            = azurerm_resource_group.instance_rg.location
  resource_group_name = azurerm_resource_group.instance_rg.name

  tags = merge(tomap({
    Service = "network_security_group"
  }), local.tags)
}

# AKS subnet
resource "azurerm_subnet" "aks" {
  name                 = "${var.prefix}-${var.project}-${var.env_name}-aks-snet"
  resource_group_name  = azurerm_virtual_network.env_vnet.resource_group_name
  virtual_network_name = azurerm_virtual_network.env_vnet.name
  address_prefixes     = ["${var.subnet_cidr_aks}"]
  service_endpoints = [
    "Microsoft.AzureActiveDirectory",
    "Microsoft.KeyVault",
    "Microsoft.Storage",
    "Microsoft.Sql"
  ]
}

# Associate AKS subnet with network security group
resource "azurerm_subnet_network_security_group_association" "aks_nsg" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

resource "azurerm_subnet" "subnet" {
  name                              = "${var.prefix}-${var.project}-${var.env_name}-snet"
  resource_group_name               = azurerm_virtual_network.env_vnet.resource_group_name
  virtual_network_name              = azurerm_virtual_network.env_vnet.name
  private_endpoint_network_policies = "Disabled"
  address_prefixes                  = ["${var.subnet_cidr}"]
  service_endpoints                 = ["Microsoft.Web", "Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.AzureCosmosDB", "Microsoft.EventHub", "Microsoft.ServiceBus"]
}