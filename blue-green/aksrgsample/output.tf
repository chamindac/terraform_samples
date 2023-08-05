output "live_rg_name" {
  value = var.green_golive ? (var.green_deploy ? module.rg_green[0].aks_rg_name : "No live cluster") : module.rg_blue[0].aks_rg_name
}

output "live_rg_tags" {
  value = var.green_golive ? (var.green_deploy ? module.rg_green[0].aks_rg_tags : tomap({ ClusterState = "No live cluster", K8Sversion = "No live cluster" })) : module.rg_blue[0].aks_rg_tags
}

output "deployed_rg_name" {
  value = var.green_golive ? (var.blue_deploy ? module.rg_blue[0].aks_rg_name : "No deployed cluster") : (var.green_deploy ? module.rg_green[0].aks_rg_name : "No deployed cluster")
}

output "deployed_rg_tags" {
  value = var.green_golive ? (var.blue_deploy ? module.rg_blue[0].aks_rg_tags : tomap({ ClusterState = "No deployed cluster", K8Sversion = "No deployed cluster" })) : (var.green_deploy ? module.rg_green[0].aks_rg_tags : tomap({ ClusterState = "No deployed cluster", K8Sversion = "No deployed cluster" }))
}

output "app_deploy_cluster" {
  value = var.green_golive ? (var.deployment_phase == "deploy" ? module.rg_blue[0].aks_rg_name : module.rg_green[0].aks_rg_name) : (var.deployment_phase == "deploy" ? module.rg_green[0].aks_rg_name : module.rg_blue[0].aks_rg_name)
}