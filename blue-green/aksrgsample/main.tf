# Just a demo rg - consider this as blue deployment
module "rg_blue" {
  source = "./modules/rg"

  count = var.blue_deploy ? 1 : 0

  resource_group_name = "ch-demo-dev-euw-001-rg-blue"
  kubernetes_version  = (var.green_golive && var.deployment_phase == "deploy") || (!var.green_golive && var.deployment_phase == "switch") ? local.kubernetes_version : var.current_kubernetes_version
  cluster_state       = var.green_golive ? (var.deployment_phase == "switch" ? "to be destroyed" : "deployed") : "live"
}

# This is green deployment for same rg
module "rg_green" {
  source = "./modules/rg"

  count = var.green_deploy ? 1 : 0

  resource_group_name = "ch-demo-dev-euw-001-rg-green"
  kubernetes_version  = (!var.green_golive && var.deployment_phase == "deploy") || (var.green_golive && var.deployment_phase == "switch") ? local.kubernetes_version : var.current_kubernetes_version
  cluster_state       = var.green_golive ? "live" : (var.deployment_phase == "switch" ? "to be destroyed" : "deployed")
}