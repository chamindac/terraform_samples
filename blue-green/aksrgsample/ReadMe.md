***AKS Blue Green Deployment - Algorithm Test***

This example uses resource group to demo a blue green deployment to keep things simple. This resource group example can be used to understand blue green deployment with terraform for AKS. Same pattern can be applied to deploy other Azure resources well. Instead of two resource groups used here to run demo faster, actual implementation can be two AKS clusters (blue and green) withing a single resource group or in two resource groups. 

Output of live resource group name and tags from terraform represents the live cluster and kubernetes version information. Test scenario is available in AKS Upgrade.xlxs file. 

A pipeline tool such as Azure DevOps pipelines or GitHub actions should be used with below defined phases of deployment..
- `deploy`: Blue (if current live is green/ fresh deployment) or green (if current live is blue) cluster deployment.
- `appdeploy`: deploy apps to newly deployed cluster which is not yet live.
- `switch`: Bring newly deployed cluster live.
- `destroy` Destroy the previous cluster.

Pipeline should define below variables.
- `blue_deploy`: Should set intial value to `true` and should not change value afterwards. 
- `green_deploy`: Should set intial value to `false` for fresh deployment or `true` if blue cluster is existing. 
- `green_golive`: Should set intial value to `true` for fresh deployment or `false` if blue cluster is existing.
- `current_k8s`: Should set as empty value for fresh deployment or set as current blue cluster k8s version if blue cluster is existing.
- `app_deploy_cluster`: Should set as empty value for fresh deployment or set as current blue cluster name if blue cluster is existing.

Pipeline should update the value as specified in below phases for all above variables. After intial setup **no manual changes should be done** to above pipeline variables. 	


***Infra `deploy` phase***
Here the Blue or Green AKS cluster gets deployed based on current live cluster. Existing cluster is not changed. If fresh deployment a blue cluster created and set as deployed but not live.

Update pipeline variable `green_golive` to NOT(`green_golive`).
Update `app_deploy_cluster` from TF output variable `app_deploy_cluster`.

***Application deployment phase `appdeploy`***
Deploy the apps to `app_deploy_cluster`.

***Infra `switch` phase***
TF will set the `app_deploy_cluster` as live cluster, by routing traffic to it.

Update pipeline variable `blue_deploy` to `false`, if `green_golive` is `true`. 
Update pipeline variable `green_deploy` to `false`, if `green_golive` is `false`. 
Update pipeline variable `current_k8s` to `K8Sversion` of the live cluster, if `current_k8s` is not equal to `K8Sversion`. 

***Infra `destroy` phase***
TF will destroy the non live cluster.

Update pipeline variable `blue_deploy` to `true`, if the current value is `false`.
Update pipeline variable `green_deploy` to `true`, if the current value is `false`.



***Trial run steps are below***

AKS Upgrade.xlxs file contains definition of the below steps. Below step detail describe each step.

Intialize terrafrom
```
terraform init
```

***Intial deployment - 001. blue deployment***
- `deploy`: Create blue cluster with infra `deploy` phase.
```
terraform apply -var deployment_phase=deploy -var blue_deploy=true -var green_deploy=false -var green_golive=true -var current_kubernetes_version="" -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_tags = tomap({
  "ClusterState" = "deployed"
  "K8Sversion" = "1.24.9"
})
live_rg_name = "No live cluster"
live_rg_tags = tomap({
  "ClusterState" = "No live cluster"
  "K8Sversion" = "No live cluster"
})
```
Update pipeline variable `green_golive` to NOT(`green_golive`).
Update `app_deploy_cluster` from TF output variable `app_deploy_cluster`.

Result:
`green_golive = true --> false`
`app_deploy_cluster = '' --> ch-demo-dev-euw-001-rg-blue`

- `appdeploy`: Application deplyment to `app_deploy_cluster`, here to blue should be done in pipeline.

- `switch`: Bring blue cluster live with infra `switch` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=switch -var blue_deploy=true -var green_deploy=false -var green_golive=false -var current_kubernetes_version="" -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "No deployed cluster"
deployed_rg_tags = tomap({
  "ClusterState" = "No deployed cluster"
  "K8Sversion" = "No deployed cluster"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.24.9"
})
```
Update pipeline variable `blue_deploy` to `false`, if `green_golive` is `true`. 
Update pipeline variable `green_deploy` to `false`, if `green_golive` is `false`. 
Update pipeline variable `current_k8s` to `K8Sversion` of the live cluster, if `current_k8s` is not equal to `K8Sversion`. 

Result:
`blue_deploy = true (no update)`
`green_deploy = false --> false (updated with no change)`
`current_k8s = '' --> 1.24.9`

- `destroy`: Destroy green cluster with infra `destroy` phase using pipeline variables as input to TF. In this instance nothing to destroy as no green cluster available.
```
terraform apply -var deployment_phase=destroy -var blue_deploy=true -var green_deploy=false -var green_golive=false -var current_kubernetes_version=1.24.9 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "No deployed cluster"
deployed_rg_tags = tomap({
  "ClusterState" = "No deployed cluster"
  "K8Sversion" = "No deployed cluster"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.24.9"
})
```
Update pipeline variable `blue_deploy` to `true`, if the current value is `false`.
Update pipeline variable `green_deploy` to `true`, if the current value is `false`.

Result:
`blue_deploy = true (no update)`
`green_deploy = false --> true`


***Next deployment - 002. green deployment***
- `deploy`: Create green cluster with infra `deploy` phase.
```
terraform apply -var deployment_phase=deploy -var blue_deploy=true -var green_deploy=true -var green_golive=false -var current_kubernetes_version=1.24.9 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "ch-demo-dev-euw-001-rg-green"
deployed_rg_tags = tomap({
  "ClusterState" = "deployed"
  "K8Sversion" = "1.24.9"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.24.9"
})
```
Update pipeline variable `green_golive` to NOT(`green_golive`).
Update `app_deploy_cluster` from TF output variable `app_deploy_cluster`.

Result:
`green_golive = false --> true`
`app_deploy_cluster = ch-demo-dev-euw-001-rg-blue --> ch-demo-dev-euw-001-rg-green`

- `appdeploy`: Application deplyment to `app_deploy_cluster`, to green should be done in pipeline.

- `switch`: Bring green cluster live with infra `switch` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=switch -var blue_deploy=true -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.24.9 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_tags = tomap({
  "ClusterState" = "to be destroyed"
  "K8Sversion" = "1.24.9"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.24.9"
})
```
Update pipeline variable `blue_deploy` to `false`, if `green_golive` is `true`. 
Update pipeline variable `green_deploy` to `false`, if `green_golive` is `false`. 
Update pipeline variable `current_k8s` to `K8Sversion` of the live cluster, if `current_k8s` is not equal to `K8Sversion`. 

Result:
`blue_deploy = true --> false`
`green_deploy = true (no update)`
`current_k8s = 1.24.9 (no update)`

- `destroy`: Destroy blue cluster with infra `destroy` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=destroy -var blue_deploy=false -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.24.9 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "No deployed cluster"
deployed_rg_tags = tomap({
  "ClusterState" = "No deployed cluster"
  "K8Sversion" = "No deployed cluster"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.24.9"
})
```
Update pipeline variable `blue_deploy` to `true`, if the current value is `false`.
Update pipeline variable `green_deploy` to `true`, if the current value is `false`.

Result:
`blue_deploy = false --> true`
`green_deploy = true (no update)`


***Next deployment - 003. blue deployment***
- `deploy`: Create blue cluster with infra `deploy` phase.
```
terraform apply -var deployment_phase=deploy -var blue_deploy=true -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.24.9 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_tags = tomap({
  "ClusterState" = "deployed"
  "K8Sversion" = "1.24.9"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.24.9"
})
```
Update pipeline variable `green_golive` to NOT(`green_golive`).
Update `app_deploy_cluster` from TF output variable `app_deploy_cluster`.

Result:
`green_golive = true --> false`
`app_deploy_cluster = ch-demo-dev-euw-001-rg-green --> ch-demo-dev-euw-001-rg-blue`

- `appdeploy`: Application deplyment to `app_deploy_cluster`, here to blue should be done in pipeline.

- `switch`: Bring blue cluster live with infra `switch` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=switch -var blue_deploy=true -var green_deploy=true -var green_golive=false -var current_kubernetes_version=1.24.9 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "ch-demo-dev-euw-001-rg-green"
deployed_rg_tags = tomap({
  "ClusterState" = "to be destroyed"
  "K8Sversion" = "1.24.9"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.24.9"
})
```
Update pipeline variable `blue_deploy` to `false`, if `green_golive` is `true`. 
Update pipeline variable `green_deploy` to `false`, if `green_golive` is `false`. 
Update pipeline variable `current_k8s` to `K8Sversion` of the live cluster, if `current_k8s` is not equal to `K8Sversion`. 

Result:
`blue_deploy = true (no update)`
`green_deploy = true --> false`
`current_k8s = 1.24.9 (no update)`

- `destroy`: Destroy green cluster with infra `destroy` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=destroy -var blue_deploy=true -var green_deploy=false -var green_golive=false -var current_kubernetes_version=1.24.9 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "No deployed cluster"
deployed_rg_tags = tomap({
  "ClusterState" = "No deployed cluster"
  "K8Sversion" = "No deployed cluster"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.24.9"
})
```
Update pipeline variable `blue_deploy` to `true`, if the current value is `false`.
Update pipeline variable `green_deploy` to `true`, if the current value is `false`.

Result:
`blue_deploy = true (no update)`
`green_deploy = false --> true`


***Next deployment - 004. green deployment***
- `deploy`: Create green cluster with infra `deploy` phase.
```
terraform apply -var deployment_phase=deploy -var blue_deploy=true -var green_deploy=true -var green_golive=false -var current_kubernetes_version=1.24.9 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "ch-demo-dev-euw-001-rg-green"
deployed_rg_tags = tomap({
  "ClusterState" = "deployed"
  "K8Sversion" = "1.24.9"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.24.9"
})
```
Update pipeline variable `green_golive` to NOT(`green_golive`).
Update `app_deploy_cluster` from TF output variable `app_deploy_cluster`.

Result:
`green_golive = false --> true`
`app_deploy_cluster = ch-demo-dev-euw-001-rg-blue --> ch-demo-dev-euw-001-rg-green`

- `appdeploy`: Application deplyment to `app_deploy_cluster`, to green should be done in pipeline.

- `switch`: Bring green cluster live with infra `switch` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=switch -var blue_deploy=true -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.24.9 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_tags = tomap({
  "ClusterState" = "to be destroyed"
  "K8Sversion" = "1.24.9"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.24.9"
})
```
Update pipeline variable `blue_deploy` to `false`, if `green_golive` is `true`. 
Update pipeline variable `green_deploy` to `false`, if `green_golive` is `false`. 
Update pipeline variable `current_k8s` to `K8Sversion` of the live cluster, if `current_k8s` is not equal to `K8Sversion`. 

Result:
`blue_deploy = true --> false`
`green_deploy = true (no update)`
`current_k8s = 1.24.9 (no update)`

- `destroy`: Destroy blue cluster with infra `destroy` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=destroy -var blue_deploy=false -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.24.9 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "No deployed cluster"
deployed_rg_tags = tomap({
  "ClusterState" = "No deployed cluster"
  "K8Sversion" = "No deployed cluster"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.24.9"
})
```
Update pipeline variable `blue_deploy` to `true`, if the current value is `false`.
Update pipeline variable `green_deploy` to `true`, if the current value is `false`.

Result:
`blue_deploy = false --> true`
`green_deploy = true (no update)`


***Next deployment - 005. blue deployment - aks upgrade to k8s 1.25.6***
- `deploy`: Update TF variables, local.kubernetes_version to `1.25.6` from `1.24.9`. Then create blue cluster with infra `deploy` phase which will have "K8Sversion" = "1.25.6". Green cluster not changed and it is live, with "K8Sversion" = "1.24.9".
```
terraform apply -var deployment_phase=deploy -var blue_deploy=true -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.24.9 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_tags = tomap({
  "ClusterState" = "deployed"
  "K8Sversion" = "1.25.6"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.24.9"
})
```
Update pipeline variable `green_golive` to NOT(`green_golive`).
Update `app_deploy_cluster` from TF output variable `app_deploy_cluster`.

Result:
`green_golive = true --> false`
`app_deploy_cluster = ch-demo-dev-euw-001-rg-green --> ch-demo-dev-euw-001-rg-blue`

- `appdeploy`: Application deplyment to `app_deploy_cluster`, here to blue should be done in pipeline.

- `switch`: Bring blue cluster live with infra `switch` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=switch -var blue_deploy=true -var green_deploy=true -var green_golive=false -var current_kubernetes_version=1.24.9 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "ch-demo-dev-euw-001-rg-green"
deployed_rg_tags = tomap({
  "ClusterState" = "to be destroyed"
  "K8Sversion" = "1.24.9"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.25.6"
})
```
Update pipeline variable `blue_deploy` to `false`, if `green_golive` is `true`. 
Update pipeline variable `green_deploy` to `false`, if `green_golive` is `false`. 
Update pipeline variable `current_k8s` to `K8Sversion` of the live cluster, if `current_k8s` is not equal to `K8Sversion`. 

Result:
`blue_deploy = true (no update)`
`green_deploy = true --> false`
`current_k8s = 1.24.9 --> 1.25.6`

- `destroy`: Destroy green cluster with infra `destroy` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=destroy -var blue_deploy=true -var green_deploy=false -var green_golive=false -var current_kubernetes_version=1.25.6 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "No deployed cluster"
deployed_rg_tags = tomap({
  "ClusterState" = "No deployed cluster"
  "K8Sversion" = "No deployed cluster"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.25.6"
})
```
Update pipeline variable `blue_deploy` to `true`, if the current value is `false`.
Update pipeline variable `green_deploy` to `true`, if the current value is `false`.

Result:
`blue_deploy = true (no update)`
`green_deploy = false --> true`


***Next deployment - 006. green deployment***
- `deploy`: Create green cluster with infra `deploy` phase.
```
terraform apply -var deployment_phase=deploy -var blue_deploy=true -var green_deploy=true -var green_golive=false -var current_kubernetes_version=1.25.6 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "ch-demo-dev-euw-001-rg-green"
deployed_rg_tags = tomap({
  "ClusterState" = "deployed"
  "K8Sversion" = "1.25.6"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.25.6"
})
```
Update pipeline variable `green_golive` to NOT(`green_golive`).
Update `app_deploy_cluster` from TF output variable `app_deploy_cluster`.

Result:
`green_golive = false --> true`
`app_deploy_cluster = ch-demo-dev-euw-001-rg-blue --> ch-demo-dev-euw-001-rg-green`

- `appdeploy`: Application deplyment to `app_deploy_cluster`, to green should be done in pipeline.

- `switch`: Bring green cluster live with infra `switch` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=switch -var blue_deploy=true -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.25.6 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_tags = tomap({
  "ClusterState" = "to be destroyed"
  "K8Sversion" = "1.25.6"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.25.6"
})
```
Update pipeline variable `blue_deploy` to `false`, if `green_golive` is `true`. 
Update pipeline variable `green_deploy` to `false`, if `green_golive` is `false`. 
Update pipeline variable `current_k8s` to `K8Sversion` of the live cluster, if `current_k8s` is not equal to `K8Sversion`. 

Result:
`blue_deploy = true --> false`
`green_deploy = true (no update)`
`current_k8s = 1.25.6 (no update)`

- `destroy`: Destroy blue cluster with infra `destroy` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=destroy -var blue_deploy=false -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.25.6 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "No deployed cluster"
deployed_rg_tags = tomap({
  "ClusterState" = "No deployed cluster"
  "K8Sversion" = "No deployed cluster"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.25.6"
})
```
Update pipeline variable `blue_deploy` to `true`, if the current value is `false`.
Update pipeline variable `green_deploy` to `true`, if the current value is `false`.

Result:
`blue_deploy = false --> true`
`green_deploy = true (no update)`


***Next deployment - 007. blue deployment***
- `deploy`: Create blue cluster with infra `deploy` phase.
```
terraform apply -var deployment_phase=deploy -var blue_deploy=true -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.25.6 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_tags = tomap({
  "ClusterState" = "deployed"
  "K8Sversion" = "1.25.6"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.25.6"
})
```
Update pipeline variable `green_golive` to NOT(`green_golive`).
Update `app_deploy_cluster` from TF output variable `app_deploy_cluster`.

Result:
`green_golive = true --> false`
`app_deploy_cluster = ch-demo-dev-euw-001-rg-green --> ch-demo-dev-euw-001-rg-blue`

- `appdeploy`: Application deplyment to `app_deploy_cluster`, here to blue should be done in pipeline.

- `switch`: Bring blue cluster live with infra `switch` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=switch -var blue_deploy=true -var green_deploy=true -var green_golive=false -var current_kubernetes_version=1.25.6 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "ch-demo-dev-euw-001-rg-green"
deployed_rg_tags = tomap({
  "ClusterState" = "to be destroyed"
  "K8Sversion" = "1.25.6"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.25.6"
})
```
Update pipeline variable `blue_deploy` to `false`, if `green_golive` is `true`. 
Update pipeline variable `green_deploy` to `false`, if `green_golive` is `false`. 
Update pipeline variable `current_k8s` to `K8Sversion` of the live cluster, if `current_k8s` is not equal to `K8Sversion`. 

Result:
`blue_deploy = true (no update)`
`green_deploy = true --> false`
`current_k8s = 1.25.6 (no update)`

- `destroy`: Destroy green cluster with infra `destroy` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=destroy -var blue_deploy=true -var green_deploy=false -var green_golive=false -var current_kubernetes_version=1.25.6 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "No deployed cluster"
deployed_rg_tags = tomap({
  "ClusterState" = "No deployed cluster"
  "K8Sversion" = "No deployed cluster"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.25.6"
})
```
Update pipeline variable `blue_deploy` to `true`, if the current value is `false`.
Update pipeline variable `green_deploy` to `true`, if the current value is `false`.

Result:
`blue_deploy = true (no update)`
`green_deploy = false --> true`


***Next deployment - 008. green deployment - aks upgrade to 1.26.3***
- `deploy`: Update TF variables, local.kubernetes_version to `1.26.3` from `1.25.6`. Then create green cluster with infra `deploy` phase which will have "K8Sversion" = "1.26.3". Blue cluster not changed and it is live, with "K8Sversion" = "1.25.6".
```
terraform apply -var deployment_phase=deploy -var blue_deploy=true -var green_deploy=true -var green_golive=false -var current_kubernetes_version=1.25.6 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "ch-demo-dev-euw-001-rg-green"
deployed_rg_tags = tomap({
  "ClusterState" = "deployed"
  "K8Sversion" = "1.26.3"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.25.6"
})
```
Update pipeline variable `green_golive` to NOT(`green_golive`).
Update `app_deploy_cluster` from TF output variable `app_deploy_cluster`.

Result:
`green_golive = false --> true`
`app_deploy_cluster = ch-demo-dev-euw-001-rg-blue --> ch-demo-dev-euw-001-rg-green`

- `appdeploy`: Application deplyment to `app_deploy_cluster`, to green should be done in pipeline.

- `switch`: Bring green cluster live with infra `switch` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=switch -var blue_deploy=true -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.25.6 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_tags = tomap({
  "ClusterState" = "to be destroyed"
  "K8Sversion" = "1.25.6"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.26.3"
})
```
Update pipeline variable `blue_deploy` to `false`, if `green_golive` is `true`. 
Update pipeline variable `green_deploy` to `false`, if `green_golive` is `false`. 
Update pipeline variable `current_k8s` to `K8Sversion` of the live cluster, if `current_k8s` is not equal to `K8Sversion`. 

Result:
`blue_deploy = true --> false`
`green_deploy = true (no update)`
`current_k8s = 1.25.6 --> 1.26.3`

- `destroy`: Destroy blue cluster with infra `destroy` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=destroy -var blue_deploy=false -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.26.3 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "No deployed cluster"
deployed_rg_tags = tomap({
  "ClusterState" = "No deployed cluster"
  "K8Sversion" = "No deployed cluster"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.26.3"
})
```
Update pipeline variable `blue_deploy` to `true`, if the current value is `false`.
Update pipeline variable `green_deploy` to `true`, if the current value is `false`.

Result:
`blue_deploy = false --> true`
`green_deploy = true (no update)`


***Next deployment - 009. blue deployment - aks upgrade to 1.27.1***
- `deploy`: Update TF variables, local.kubernetes_version to `1.27.1` from `1.26.3`. Then create blue cluster with infra `deploy` phase which will have "K8Sversion" = "1.27.1". Green cluster not changed and it is live, with "K8Sversion" = "1.26.3".
```
terraform apply -var deployment_phase=deploy -var blue_deploy=true -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.26.3 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_tags = tomap({
  "ClusterState" = "deployed"
  "K8Sversion" = "1.27.1"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.26.3"
})
```
Update pipeline variable `green_golive` to NOT(`green_golive`).
Update `app_deploy_cluster` from TF output variable `app_deploy_cluster`.

Result:
`green_golive = true --> false`
`app_deploy_cluster = ch-demo-dev-euw-001-rg-green --> ch-demo-dev-euw-001-rg-blue`

- `appdeploy`: Application deplyment to `app_deploy_cluster`, here to blue should be done in pipeline.

- `switch`: Bring blue cluster live with infra `switch` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=switch -var blue_deploy=true -var green_deploy=true -var green_golive=false -var current_kubernetes_version=1.26.3 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "ch-demo-dev-euw-001-rg-green"
deployed_rg_tags = tomap({
  "ClusterState" = "to be destroyed"
  "K8Sversion" = "1.26.3"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.27.1"
})
```
Update pipeline variable `blue_deploy` to `false`, if `green_golive` is `true`. 
Update pipeline variable `green_deploy` to `false`, if `green_golive` is `false`. 
Update pipeline variable `current_k8s` to `K8Sversion` of the live cluster, if `current_k8s` is not equal to `K8Sversion`. 

Result:
`blue_deploy = true (no update)`
`green_deploy = true --> false`
`current_k8s = 1.26.3 --> 1.27.1`

- `destroy`: Destroy green cluster with infra `destroy` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=destroy -var blue_deploy=true -var green_deploy=false -var green_golive=false -var current_kubernetes_version=1.27.1 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "No deployed cluster"
deployed_rg_tags = tomap({
  "ClusterState" = "No deployed cluster"
  "K8Sversion" = "No deployed cluster"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.27.1"
})
```
Update pipeline variable `blue_deploy` to `true`, if the current value is `false`.
Update pipeline variable `green_deploy` to `true`, if the current value is `false`.

Result:
`blue_deploy = true (no update)`
`green_deploy = false --> true`


***Next deployment - 010. green deployment***
- `deploy`: Create green cluster with infra `deploy` phase.
```
terraform apply -var deployment_phase=deploy -var blue_deploy=true -var green_deploy=true -var green_golive=false -var current_kubernetes_version=1.27.1 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "ch-demo-dev-euw-001-rg-green"
deployed_rg_tags = tomap({
  "ClusterState" = "deployed"
  "K8Sversion" = "1.27.1"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.27.1"
})
```
Update pipeline variable `green_golive` to NOT(`green_golive`).
Update `app_deploy_cluster` from TF output variable `app_deploy_cluster`.

Result:
`green_golive = false --> true`
`app_deploy_cluster = ch-demo-dev-euw-001-rg-blue --> ch-demo-dev-euw-001-rg-green`

- `appdeploy`: Application deplyment to `app_deploy_cluster`, to green should be done in pipeline.

- `switch`: Bring green cluster live with infra `switch` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=switch -var blue_deploy=true -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.27.1 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_tags = tomap({
  "ClusterState" = "to be destroyed"
  "K8Sversion" = "1.27.1"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.27.1"
})
```
Update pipeline variable `blue_deploy` to `false`, if `green_golive` is `true`. 
Update pipeline variable `green_deploy` to `false`, if `green_golive` is `false`. 
Update pipeline variable `current_k8s` to `K8Sversion` of the live cluster, if `current_k8s` is not equal to `K8Sversion`. 

Result:
`blue_deploy = true --> false`
`green_deploy = true (no update)`
`current_k8s = 1.27.1 (no update)`

- `destroy`: Destroy blue cluster with infra `destroy` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=destroy -var blue_deploy=false -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.27.1 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-green"
deployed_rg_name = "No deployed cluster"
deployed_rg_tags = tomap({
  "ClusterState" = "No deployed cluster"
  "K8Sversion" = "No deployed cluster"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.27.1"
})
```
Update pipeline variable `blue_deploy` to `true`, if the current value is `false`.
Update pipeline variable `green_deploy` to `true`, if the current value is `false`.

Result:
`blue_deploy = false --> true`
`green_deploy = true (no update)`


***Next deployment - 010. blue deployment***
- `deploy`: Create blue cluster with infra `deploy` phase.
```
terraform apply -var deployment_phase=deploy -var blue_deploy=true -var green_deploy=true -var green_golive=true -var current_kubernetes_version=1.27.1 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_tags = tomap({
  "ClusterState" = "deployed"
  "K8Sversion" = "1.27.1"
})
live_rg_name = "ch-demo-dev-euw-001-rg-green"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.27.1"
})
```
Update pipeline variable `green_golive` to NOT(`green_golive`).
Update `app_deploy_cluster` from TF output variable `app_deploy_cluster`.

Result:
`green_golive = true --> false`
`app_deploy_cluster = ch-demo-dev-euw-001-rg-green --> ch-demo-dev-euw-001-rg-blue`

- `appdeploy`: Application deplyment to `app_deploy_cluster`, here to blue should be done in pipeline.

- `switch`: Bring blue cluster live with infra `switch` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=switch -var blue_deploy=true -var green_deploy=true -var green_golive=false -var current_kubernetes_version=1.27.1 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "ch-demo-dev-euw-001-rg-green"
deployed_rg_tags = tomap({
  "ClusterState" = "to be destroyed"
  "K8Sversion" = "1.27.1"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.27.1"
})
```
Update pipeline variable `blue_deploy` to `false`, if `green_golive` is `true`. 
Update pipeline variable `green_deploy` to `false`, if `green_golive` is `false`. 
Update pipeline variable `current_k8s` to `K8Sversion` of the live cluster, if `current_k8s` is not equal to `K8Sversion`. 

Result:
`blue_deploy = true (no update)`
`green_deploy = true --> false`
`current_k8s = 1.27.1 (no update)`

- `destroy`: Destroy green cluster with infra `destroy` phase using pipeline variables as input to TF.
```
terraform apply -var deployment_phase=destroy -var blue_deploy=true -var green_deploy=false -var green_golive=false -var current_kubernetes_version=1.27.1 -auto-approve
```
TF output
```
app_deploy_cluster = "ch-demo-dev-euw-001-rg-blue"
deployed_rg_name = "No deployed cluster"
deployed_rg_tags = tomap({
  "ClusterState" = "No deployed cluster"
  "K8Sversion" = "No deployed cluster"
})
live_rg_name = "ch-demo-dev-euw-001-rg-blue"
live_rg_tags = tomap({
  "ClusterState" = "live"
  "K8Sversion" = "1.27.1"
})
```
Update pipeline variable `blue_deploy` to `true`, if the current value is `false`.
Update pipeline variable `green_deploy` to `true`, if the current value is `false`.

Result:
`blue_deploy = true (no update)`
`green_deploy = false --> true`