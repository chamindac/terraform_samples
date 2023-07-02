locals {
  kubernetes_version = "1.24.9"
}

variable "green_golive" {
  default = false
  type    = bool
}

variable "green_deploy" {
  default = false
  type    = bool
}

variable "blue_deploy" {
  default = true
  type    = bool
}

variable "deployment_phase" {
  default = "deploy"
  type    = string

  validation {
    condition     = contains(["deploy", "switch", "destroy"], var.deployment_phase)
    error_message = "Valid values for var.deployment_phase are: (deploy, switch or destroy)."
  }
}

variable "current_kubernetes_version" {
  type = string
}