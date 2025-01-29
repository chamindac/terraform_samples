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
  subscription_id = "subscriptionid"
}

resource "azurerm_resource_group" "instance_rg" {
  name     = "ch-alerttest-dev-eus-001-rg"
  location = "eastus"
}

resource "azurerm_storage_account" "filestorage_aks_win" {
  name                             = "chatdeveus001akswfsgreen"
  location                         = azurerm_resource_group.instance_rg.location
  resource_group_name              = azurerm_resource_group.instance_rg.name
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  account_kind                     = "StorageV2"
  access_tier                      = "Hot"
  allow_nested_items_to_be_public  = false
  min_tls_version                  = "TLS1_2"
  cross_tenant_replication_enabled = false

  network_rules {
    default_action = "Deny"
    bypass         = ["Metrics", "AzureServices", "Logging"]
    ip_rules       = ["46.15.119.116"]
  }
}

resource "azurerm_storage_account" "filestorage_aks_linux" {
  name                             = "chatdeveus001akslfsgreen"
  location                         = azurerm_resource_group.instance_rg.location
  resource_group_name              = azurerm_resource_group.instance_rg.name
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  account_kind                     = "StorageV2"
  access_tier                      = "Hot"
  allow_nested_items_to_be_public  = false
  min_tls_version                  = "TLS1_2"
  cross_tenant_replication_enabled = false

  network_rules {
    default_action = "Deny"
    bypass         = ["Metrics", "AzureServices", "Logging"]
    ip_rules       = ["46.15.119.116"]
  }
}

resource "azurerm_storage_share" "aks_windows" {
  name               = "akswindowsfileshare"
  storage_account_id = azurerm_storage_account.filestorage_aks_win.id
  access_tier        = "Hot"
  quota              = 100 # Size in GB (Max 5TB since large file share not enabled in storage)
}

resource "azurerm_storage_share" "aks_linux" {
  name               = "akslinuxfileshare"
  storage_account_id = azurerm_storage_account.filestorage_aks_linux.id
  access_tier        = "Hot"
  quota              = 100 # Size in GB (Max 5TB since large file share not enabled in storage)
}

# Action group
resource "azurerm_monitor_action_group" "fileshare_capacity_action" {
  name                = "AKSFileShareCapacityAlert"
  resource_group_name = azurerm_resource_group.instance_rg.name
  short_name          = "fscapacity"

  email_receiver {
    name                    = "sendtodemoslack"
    email_address           = "chaminda-test-aaaapgfgbiallammgkxylwwdrq@mycompany.slack.com"
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "aks_fs_win" {
  name                 = "${azurerm_storage_account.filestorage_aks_win.name}-${azurerm_storage_share.aks_windows.name}-capacity-alert"
  resource_group_name  = azurerm_resource_group.instance_rg.name
  scopes               = ["${azurerm_storage_account.filestorage_aks_win.id}/fileservices/default"]
  description          = "AKS file share ${azurerm_storage_account.filestorage_aks_win.name}/${azurerm_storage_share.aks_windows.name} reached 80% capacity"
  enabled              = true
  auto_mitigate        = true
  frequency            = "PT1M"
  window_size          = "PT1H"
  severity             = 2
  target_resource_type = "Microsoft.Storage/storageAccounts/fileservices"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts/fileservices"
    metric_name      = "FileCapacity"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = 4294967296
  }

  action {
    action_group_id = azurerm_monitor_action_group.fileshare_capacity_action.id
  }
}

resource "azurerm_monitor_metric_alert" "aks_fs_linux" {
  name                 = "${azurerm_storage_account.filestorage_aks_linux.name}-${azurerm_storage_share.aks_linux.name}-capacity-alert"
  resource_group_name  = azurerm_resource_group.instance_rg.name
  scopes               = ["${azurerm_storage_account.filestorage_aks_linux.id}/fileservices/default"]
  description          = "AKS file share ${azurerm_storage_account.filestorage_aks_linux.name}/${azurerm_storage_share.aks_linux.name} reached 80% capacity"
  enabled              = true
  auto_mitigate        = true
  frequency            = "PT1M"
  window_size          = "PT1H"
  severity             = 2
  target_resource_type = "Microsoft.Storage/storageAccounts/fileservices"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts/fileservices"
    metric_name      = "FileCapacity"
    aggregation      = "Average"
    operator         = "GreaterThanOrEqual"
    threshold        = 2147483648
  }

  action {
    action_group_id = azurerm_monitor_action_group.fileshare_capacity_action.id
  }
}