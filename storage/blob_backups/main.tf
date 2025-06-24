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
  subscription_id = "subscriptionid"
}

resource "azurerm_resource_group" "instance_rg" {
  name     = "ch-blobbackup-dev-weu-001-rg"
  location = "westeurope"
}

resource "azurerm_resource_group" "shared_rg" {
  name     = "ch-blobbackup-dev-weu-shared-rg"
  location = "westeurope"
}

resource "azurerm_storage_account" "instancestoragecool" {
  name                             = "chdemodevweu001cool"
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
      days                     = 12
      permanent_delete_enabled = false
    }

    container_delete_retention_policy {
      days = 30
    }

    restore_policy {
      days = 7
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}



resource "azurerm_storage_management_policy" "cool_storage_version_cleanup" {
  storage_account_id = azurerm_storage_account.instancestoragecool.id

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
  name                             = "chdemodevweu001hot"
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
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy {
      days                     = 12
      permanent_delete_enabled = false
    }

    container_delete_retention_policy {
      days = 7
    }

    restore_policy {
      days = 7
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "cool_storage_images" {
  name                  = "images"
  storage_account_id    = azurerm_storage_account.instancestoragecool.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "cool_storage_videos" {
  name                  = "videos"
  storage_account_id    = azurerm_storage_account.instancestoragecool.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "hot_storage_images" {
  name                  = "images"
  storage_account_id    = azurerm_storage_account.instancestoragehot.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "hot_storage_videos" {
  name                  = "videos"
  storage_account_id    = azurerm_storage_account.instancestoragehot.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_data_protection_backup_vault" "backup_vault" {
  name                = "ch-blobbackup-dev-weu-bv"
  location            = azurerm_resource_group.shared_rg.location
  resource_group_name = azurerm_resource_group.shared_rg.name
  datastore_type      = "VaultStore"
  redundancy          = "GeoRedundant"
  soft_delete         = "Off" # Set to Off to delete the backup instances via TF

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "cool_storage_backup_role" {
  principal_id         = azurerm_data_protection_backup_vault.backup_vault.identity[0].principal_id
  role_definition_name = "Storage Account Backup Contributor"
  scope                = azurerm_storage_account.instancestoragecool.id
}

resource "azurerm_role_assignment" "hot_storage_backup_role" {
  principal_id         = azurerm_data_protection_backup_vault.backup_vault.identity[0].principal_id
  role_definition_name = "Storage Account Backup Contributor"
  scope                = azurerm_storage_account.instancestoragehot.id
}

# Backup Policy for Blob Storage
resource "azurerm_data_protection_backup_policy_blob_storage" "cool_storage_backup_policy" {
  name     = "${azurerm_storage_account.instancestoragecool.name}-blob-policy"
  vault_id = azurerm_data_protection_backup_vault.backup_vault.id

  operational_default_retention_duration = "P7D"
  vault_default_retention_duration       = "P30D"
  time_zone                              = "W. Europe Standard Time"
  backup_repeating_time_intervals        = ["R/2025-06-23T19:00:00/P1D"] # take backup every day

  depends_on = [azurerm_role_assignment.cool_storage_backup_role]
}

resource "azurerm_data_protection_backup_policy_blob_storage" "hot_storage_backup_policy" {
  name     = "${azurerm_storage_account.instancestoragehot.name}-blob-policy"
  vault_id = azurerm_data_protection_backup_vault.backup_vault.id

  operational_default_retention_duration = "P7D" # ISO 8601 Duration: 7 days - operational backup retention days
  vault_default_retention_duration       = "P7D"
  time_zone                              = "W. Europe Standard Time"
  backup_repeating_time_intervals        = ["R/2025-06-23T19:00:00/P1D"] # take backup every day

  depends_on = [azurerm_role_assignment.hot_storage_backup_role]
}

# Backup Instance to protect Blob Storage
resource "azurerm_data_protection_backup_instance_blob_storage" "cool_storage_backup_instance" {
  name                            = "${azurerm_storage_account.instancestoragecool.name}-backup-instance"
  vault_id                        = azurerm_data_protection_backup_vault.backup_vault.id
  location                        = azurerm_storage_account.instancestoragecool.location
  storage_account_id              = azurerm_storage_account.instancestoragecool.id
  backup_policy_id                = azurerm_data_protection_backup_policy_blob_storage.cool_storage_backup_policy.id
  storage_account_container_names = ["images", "videos"]

  depends_on = [
    azurerm_role_assignment.cool_storage_backup_role,
    azurerm_data_protection_backup_policy_blob_storage.cool_storage_backup_policy,
    azurerm_storage_container.cool_storage_images,
    azurerm_storage_container.cool_storage_videos
  ]
}

resource "azurerm_data_protection_backup_instance_blob_storage" "hot_storage_backup_instance" {
  name                            = "${azurerm_storage_account.instancestoragehot.name}-backup-instance"
  vault_id                        = azurerm_data_protection_backup_vault.backup_vault.id
  location                        = azurerm_storage_account.instancestoragehot.location
  storage_account_id              = azurerm_storage_account.instancestoragehot.id
  backup_policy_id                = azurerm_data_protection_backup_policy_blob_storage.hot_storage_backup_policy.id
  storage_account_container_names = ["images", "videos"]

  depends_on = [
    azurerm_role_assignment.hot_storage_backup_role,
    azurerm_data_protection_backup_policy_blob_storage.hot_storage_backup_policy,
    azurerm_storage_container.hot_storage_images,
    azurerm_storage_container.hot_storage_videos
  ]
}