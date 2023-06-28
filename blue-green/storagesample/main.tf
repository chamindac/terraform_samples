resource "azurerm_resource_group" "rg" {
  name     = "ch-demo-dev-euw-001-rg"
  location = "westeurope"
}

# Just a demo storage - consider this as blue deployment
module "storage_blue" {
  source = "./modules/storage"

  count = var.blue_deploy ? 1 : 0

  storage_name             = "chdemodeveuw001blue"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
}

# This is green deployment for same storage
module "storage_green" {
  source = "./modules/storage"

  count = var.green_deploy ? 1 : 0

  storage_name             = "chdemodeveuw001green"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
}