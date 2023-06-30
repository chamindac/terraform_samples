output "aks_rg_name" {
  value     = azurerm_resource_group.demo.name
}

output "aks_rg_tags" {
  value = azurerm_resource_group.demo.tags
}