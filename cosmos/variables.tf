# Locals
locals {
  
  tags = {
    Environment          = var.env
    Owner                = "Demo Team"
    System               = "Demo"
    SystemClassification = "Internal"
    CreatedBy            = data.azurerm_client_config.current.object_id
    EnvName              = var.env_name
    ProvisionedWith      = "Terraform"
  }
}

#region common variables
variable "env" {
  description = "Env name"
  type        = string
}

variable "env_name" {
  description = "Full env name"
  type        = string
}

variable "prefix" {
  description = "Project prefix"
  type        = string
}

variable "project" {
  description = "project name or shortcode"
  type        = string
}

variable "region" {
  description = "What region the instance is running in."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription id"
  type        = string
}

variable "tenant_id" {
  description = "Azure subscription id"
  type        = string
}
#endregion