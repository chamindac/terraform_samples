variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "cluster_state" {
  description = "AKS cluster live or not"
  type        = string
}

variable "kubernetes_version" {
  description = "AKS cluster k8s version"
  type        = string
}