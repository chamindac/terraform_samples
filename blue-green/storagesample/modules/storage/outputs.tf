output "storage_connection_string" {
  value     = azurerm_storage_account.demo.primary_connection_string
  sensitive = true
}

output "storage_name" {
  value = azurerm_storage_account.demo.name
}