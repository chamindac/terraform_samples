terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.33.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=3.4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "ab296514-2304-4132-97d7-95c888d9d0ab"
}

resource "azurerm_resource_group" "instance_rg" {
  name     = "ch-stbackup-dev-weu-001-rg"
  location = "westeurope"
}

resource "azurerm_storage_account" "instancestoragecold" {
  name                             = "chbackupdevweu001cold"
  location                         = azurerm_resource_group.instance_rg.location
  resource_group_name              = azurerm_resource_group.instance_rg.name
  account_tier                     = "Standard"
  account_replication_type         = "RAGRS"
  account_kind                     = "StorageV2"
  access_tier                      = "Cool"
  allow_nested_items_to_be_public  = false
  min_tls_version                  = "TLS1_2"
  cross_tenant_replication_enabled = false

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
    # No need as we are setting up backup
    # restore_policy {
    #   days = 6
    # }
  }

  lifecycle {
    prevent_destroy = true
  }
}



resource "azurerm_storage_management_policy" "cold_storage_version_cleanup" {
  storage_account_id = azurerm_storage_account.instancestoragecold.id

  rule {
    name    = "DeletePreviousVersions (auto-created)"
    enabled = true

    filters {
      blob_types = ["blockBlob", "appendBlob"]
      # optional: limit to specific prefixes
      # prefix_match = ["myprefix/"]
    }

    actions {
      version {
        delete_after_days_since_creation = 7
      }
    }
  }
}

resource "azurerm_storage_account" "instancestoragehot" {
  name                             = "chbackupdevweu001hot"
  location                         = azurerm_resource_group.instance_rg.location
  resource_group_name              = azurerm_resource_group.instance_rg.name
  account_tier                     = "Standard"
  account_replication_type         = "RAGRS"
  account_kind                     = "StorageV2"
  access_tier                      = "Hot"
  allow_nested_items_to_be_public  = false
  min_tls_version                  = "TLS1_2"
  cross_tenant_replication_enabled = false

  blob_properties {
    versioning_enabled            = true
    change_feed_enabled           = true
    change_feed_retention_in_days = 30

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }

    # No need as we are setting up backup
    # restore_policy {
    #   days = 6
    # }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_data_protection_backup_vault" "backup_vault" {
  name                = "ch-stbackup-dev-weu-bv"
  location            = azurerm_resource_group.instance_rg.location
  resource_group_name = azurerm_resource_group.instance_rg.name
  datastore_type      = "VaultStore"
  redundancy          = "GeoRedundant"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "cold_storage_backup_role" {
  principal_id         = azurerm_data_protection_backup_vault.backup_vault.identity[0].principal_id
  role_definition_name = "Storage Account Backup Contributor"
  scope                = azurerm_storage_account.instancestoragecold.id
}

resource "azurerm_role_assignment" "hot_storage_backup_role" {
  principal_id         = azurerm_data_protection_backup_vault.backup_vault.identity[0].principal_id
  role_definition_name = "Storage Account Backup Contributor"
  scope                = azurerm_storage_account.instancestoragehot.id
}

# # Backup Policy for Blob Storage
# resource "azurerm_data_protection_backup_policy_blob_storage" "example" {
#   name                = "example-blob-policy"
#   vault_name          = azurerm_data_protection_backup_vault.example.name
#   resource_group_name = azurerm_resource_group.example.name

#   default_retention_duration = "P30D"  # ISO 8601 Duration: 30 days
#   backup_frequency           = "Daily"
#   backup_start_time         = "2024-01-01T02:00:00Z"
# }

# # Backup Instance to protect Blob Storage
# resource "azurerm_data_protection_backup_instance_blob_storage" "example" {
#   name                          = "example-blob-backup-instance"
#   vault_id                      = azurerm_data_protection_backup_vault.example.id
#   location                      = azurerm_resource_group.example.location
#   storage_account_id            = azurerm_storage_account.example.id
#   backup_policy_id              = azurerm_data_protection_backup_policy_blob_storage.example.id
#   resource_group_name           = azurerm_resource_group.example.name
#   datasource_type               = "Microsoft.Storage/storageAccounts/blobServices"
# }