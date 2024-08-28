resource "azurerm_resource_group" "instance_rg" {
  name     = "${var.prefix}-${var.project}-${var.env_name}-rg"
  location = var.region

  tags = merge(tomap({
    Service = "resource group"
  }), local.tags)
}