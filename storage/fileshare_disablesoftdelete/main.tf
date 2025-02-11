terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.16.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=3.1.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.SUBSCRIPTIONID
}

resource "azurerm_resource_group" "instance_rg" {
  name     = "ch-nosoftdel-dev-eus-001-rg"
  location = "westeurope"
}

resource "azurerm_storage_account" "filestorage_aks_win" {
  name                             = "chfsdeveus001akswfsgreen"
  location                         = azurerm_resource_group.instance_rg.location
  resource_group_name              = azurerm_resource_group.instance_rg.name
  account_tier                     = "Premium"
  account_replication_type         = "LRS"
  account_kind                     = "FileStorage"
  access_tier                      = "Hot"
  allow_nested_items_to_be_public  = false
  min_tls_version                  = "TLS1_2"
  cross_tenant_replication_enabled = false

  network_rules {
    default_action = "Deny"
    bypass         = ["Metrics", "AzureServices", "Logging"]
    ip_rules       = ["46.15.35.113"]
  }
}

resource "azurerm_storage_account" "filestorage_aks_linux" {
  name                             = "chfsdeveus001akslfsgreen"
  location                         = azurerm_resource_group.instance_rg.location
  resource_group_name              = azurerm_resource_group.instance_rg.name
  account_tier                     = "Premium"
  account_replication_type         = "LRS"
  account_kind                     = "FileStorage"
  access_tier                      = "Hot"
  allow_nested_items_to_be_public  = false
  min_tls_version                  = "TLS1_2"
  cross_tenant_replication_enabled = false

  network_rules {
    default_action = "Deny"
    bypass         = ["Metrics", "AzureServices", "Logging"]
    ip_rules       = ["46.15.35.113"]
  }
}

resource "null_resource" "disble_soft_delete_fileshares" {

  lifecycle {
    ignore_changes = []
  }

  depends_on = [
    azurerm_storage_account.filestorage_aks_win,
    azurerm_storage_account.filestorage_aks_linux
  ]

  provisioner "local-exec" {
    command     = <<-SHELL
      az login --service-principal -u ${var.DEVOPSSERVICECONNECTIONAID} -p ${var.DEVOPSSERVICECONNECTIONPW} --tenant ${var.TENANTID}
      az storage account file-service-properties update --resource-group ${azurerm_resource_group.instance_rg.name} --account-name ${azurerm_storage_account.filestorage_aks_win.name} --enable-delete-retention false --subscription ${var.SUBSCRIPTIONID}
      az storage account file-service-properties update --resource-group ${azurerm_resource_group.instance_rg.name} --account-name ${azurerm_storage_account.filestorage_aks_linux.name} --enable-delete-retention false --subscription ${var.SUBSCRIPTIONID}
    SHELL
    interpreter = ["PowerShell"]
  }
}

resource "azurerm_storage_share" "aks_windows" {
  name               = "akswindowsfileshare"
  storage_account_id = azurerm_storage_account.filestorage_aks_win.id
  access_tier        = "Premium"
  quota              = 200 # Size in GB (Max 5TB since large file share not enabled in storage)

  depends_on = [
    null_resource.disble_soft_delete_fileshares
  ]
}

resource "azurerm_storage_share" "aks_linux" {
  name               = "akslinuxfileshare"
  storage_account_id = azurerm_storage_account.filestorage_aks_linux.id
  access_tier        = "Premium"
  quota              = 100 # Size in GB (Max 5TB since large file share not enabled in storage)

  depends_on = [
    null_resource.disble_soft_delete_fileshares
  ]
}