output "storage_connection_string" {
  value     = var.green_live ? module.storage_green[0].storage_connection_string : module.storage_blue[0].storage_connection_string
  sensitive = true
}

output "storage_name" {
  value = var.green_live ? module.storage_green[0].storage_name :  module.storage_blue[0].storage_name
}