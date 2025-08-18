terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.40.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=3.5.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "2.6.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = local.subscription_id
}

# resource group for redis
resource "azurerm_resource_group" "rg" {
  name     = "ch-demo-dev01-rg"
  location = "eastus2"
}

# Azure Managed Redis
resource "azapi_resource" "managed_redis" {
  type      = "Microsoft.Cache/redisEnterprise@2025-04-01"
  name      = "ch-demo-dev01-redis"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  body = {
    properties = {
      highAvailability  = "Enabled"
      minimumTlsVersion = "1.2"
    }
    sku = {
      name = "Balanced_B0"
    }
  }

  schema_validation_enabled = true
}

resource "azapi_resource" "managed_redis_database" {
  type      = "Microsoft.Cache/redisEnterprise/databases@2025-04-01"
  name      = "default"
  parent_id = azapi_resource.managed_redis.id

  body = {
    properties = {
      clientProtocol   = "Encrypted"
      evictionPolicy   = "NoEviction"
      clusteringPolicy = "EnterpriseCluster"
      deferUpgrade     = "NotDeferred"
      modules = [
        {
          name = "RedisBloom"
        },
        {
          name = "RediSearch"
        },
        {
          name = "RedisTimeSeries"
        },
        {
          name = "RedisJSON"
        }
      ]
      persistence = {
        aofEnabled = true
        rdbEnabled = false
      }
      accessKeysAuthentication = "Enabled"
      port = local.redis_port
    }
  }

  depends_on = [
    azapi_resource.managed_redis
  ]

  schema_validation_enabled = true
}

output "redis_hostname" {
  value = azapi_resource.managed_redis.output.properties.hostName
}

output "redis_port" {
  value = local.redis_port
}

resource "null_resource" "redis_key" {

  triggers = {
    always_run = timestamp()
  }

  depends_on = [
    azapi_resource.managed_redis,
    azapi_resource.managed_redis_database
  ]

  provisioner "local-exec" {
    command     = <<-SHELL
      az login --service-principal -u ${local.spn_app_id} -p ${local.spn_pwd} --tenant ${local.tenant_id}
      az extension add --name redisenterprise --upgrade --yes
      $key = az redisenterprise database list-keys --cluster-name ${azapi_resource.managed_redis.name} --resource-group ${azurerm_resource_group.rg.name} --query primaryKey --output tsv
      $json = @{ primary_key = $key } | ConvertTo-Json -Compress
      $json | Out-File -FilePath redis_key.json -Encoding utf8
    SHELL
    interpreter = ["PowerShell"]
  }
}

data "external" "redis_key" {
  program = ["PowerShell", "./read-redis-key.ps1"]

  depends_on = [ null_resource.redis_key ]
}

output "redis_primary_access_key" {
  value     = data.external.redis_key.result.primary_key
  sensitive = true
}