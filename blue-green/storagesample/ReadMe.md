Blue Green Deployment

This example uses storage account to demo a blue green deployment to keep things simple. Deploying resource such as AKS with blue green deployment is more relavant. However, the example below using storage account can be used to understand blue green deployment with terraform. Same pattern can be applied to deploy other Azure resources such as AKS, which would be really effective to acheive zero downtime for applications deployed to AKS, even while you upgrade AKS.

Outut storage name from terraform represents the live storage for demo purpose.

Intialize terrafrom
`terraform init`

***Intial deployment blue as live***
- Create storage blue - blue is live now
`terraform apply -auto-approve`
or
`terraform apply -var blue_deploy=true -var green_deploy=false -var green_live=false -auto-approve`

***Next deployment from blue to green***
 - Green storage deployment - keep blue live
`terraform apply -var blue_deploy=true -var green_deploy=true -var green_live=false -auto-approve`

- Make green storage live
`terraform apply -var blue_deploy=true -var green_deploy=true -var green_live=true -auto-approve`

- Destroy blue storage - keep green live
`terraform apply -var blue_deploy=false -var green_deploy=true -var green_live=true -auto-approve`

***Next deployment from green to blue***
 - Blue storage deployment - keep green live
`terraform apply -var blue_deploy=true -var green_deploy=true -var green_live=true -auto-approve`

- Make blue storage live
`terraform apply -var blue_deploy=true -var green_deploy=true -var green_live=false -auto-approve`

- Destroy green storage - keep blue live
`terraform apply -var blue_deploy=false -var green_deploy=true -var green_live=true -auto-approve`