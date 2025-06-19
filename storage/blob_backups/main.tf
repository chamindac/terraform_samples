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
  subscription_id = "subscription"
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
    delete_retention_policy {
      days = 30
    }
    versioning_enabled  = true
    change_feed_enabled = true

    restore_policy {
      days = 6
    }
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
      blob_types = ["blockBlob","appendBlob"]
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
    delete_retention_policy {
      days = 7
    }

    versioning_enabled            = true
    change_feed_enabled           = true
    change_feed_retention_in_days = 30

    restore_policy {
      days = 6
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}