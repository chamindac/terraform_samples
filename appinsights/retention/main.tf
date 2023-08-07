terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.68.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# resource group for app insights
resource "azurerm_resource_group" "rg" {
  name     = "rg-appinsigtsdemo-dev01"
  location = "eastus"
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "log-appinsigtsdemo-dev01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "app_insights" {
  name                 = "appi-appinsigtsdemo-dev01"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  workspace_id         = azurerm_log_analytics_workspace.log_analytics.id
  application_type     = "web"
  daily_data_cap_in_gb = 10
  retention_in_days    = 30
}

resource "null_resource" "log_analytics_table_retention" {
  for_each = toset([
    "AppAvailabilityResults",
    "AppBrowserTimings",
    "AppDependencies",
    "AppEvents", 
    "AppExceptions",
    "AppMetrics",
    "AppPageViews",
    "AppPerformanceCounters",
    "AppRequests",
    "AppSystemEvents",
    "AppTraces",
  ])

  provisioner "local-exec" {
    command = <<-SHELL
      az login --service-principal -u ${var.DEVOPSSERVICECONNECTIONAID} -p ${var.DEVOPSSERVICECONNECTIONPW} --tenant ${var.TENANTID}
      az monitor log-analytics workspace table update --resource-group ${azurerm_resource_group.rg.name} --workspace-name ${azurerm_log_analytics_workspace.log_analytics.name} --name ${each.key} --retention-time 30 --total-retention-time 30 --subscription ${var.SUBSCRIPTIONID}
    SHELL

    interpreter = [ "PowerShell" ]
  }

  depends_on = [ 
    azurerm_application_insights.app_insights
   ]
}