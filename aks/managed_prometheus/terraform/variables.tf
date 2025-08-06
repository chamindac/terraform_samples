locals {
  kubernetes_version = "1.33.2"
  subscription_id    = "subscription_id"
  tenant_id          = "tenant_id"
  spn_app_id         = "spn_app_id"
  spn_pwd            = "spn_pwd" # replace with your actual service principal password

  log_dataflow_streams = [
    "Microsoft-ContainerLogV2",
    "Microsoft-KubeEvents",
    "Microsoft-KubePodInventory",
    "Microsoft-KubeNodeInventory",
    "Microsoft-KubePVInventory",
    "Microsoft-KubeServices",
    "Microsoft-KubeMonAgentEvents",
    "Microsoft-InsightsMetrics",
    "Microsoft-ContainerInventory",
    "Microsoft-ContainerNodeInventory",
    "Microsoft-Perf"
  ]

  enable_high_log_scale_mode = contains(local.log_dataflow_streams, "Microsoft-ContainerLogV2-HighScale")
}