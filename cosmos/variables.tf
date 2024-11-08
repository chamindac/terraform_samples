locals {
  dev_environment = "dev"
  qa_environment  = "qa"

  cosmosdb_regions_none_prod = [
    {
      location          = azurerm_resource_group.instance_rg.location,
      failover_priority = 0
    }
  ]

  cosmosdb_regions_prod = [
    {
      location          = azurerm_resource_group.instance_rg.location,
      failover_priority = 0
    },
    {
      location          = var.SECONDARYREGION,
      failover_priority = 1
    }
  ]
}

variable "SECONDARYREGION" {
  description = "Secondary region."
  type        = string
  default     = "westus"
}

variable "ENV" {
  description = "dev/qa/prd"
  type        = string
  default     = "dev"
}