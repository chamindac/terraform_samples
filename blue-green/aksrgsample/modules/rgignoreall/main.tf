resource "azurerm_resource_group" "demo" {
  name     = var.resource_group_name
  location = "westeurope"

  tags = {
    ClusterState = var.cluster_state,
    K8Sversion  = var.kubernetes_version
  }

  lifecycle {
    ignore_changes = all
  }
}