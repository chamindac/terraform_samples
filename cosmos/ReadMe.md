Use `az login` to login to Azure with an SPN
```
az login --service-principal --username <spnappid> --password <spnapppwd> --tenant <tenantid>
az account set --subscription $subscriptionid  
[Environment]::SetEnvironmentVariable("ARM_CLIENT_ID", <spnappid>)
[Environment]::SetEnvironmentVariable("ARM_CLIENT_SECRET", <spnapppwd>)
[Environment]::SetEnvironmentVariable("ARM_SUBSCRIPTION_ID", <subscriptionid>)
[Environment]::SetEnvironmentVariable("ARM_TENANT_ID", <tenantid>)
```
or use `az login` to login to Azure with a user
```
az login --service-principal --username <spnappid> --password <spnapppwd> --tenant <tenantid>
az account set --subscription <subscriptionid> 
```

Use below comands with `env.tfvars` and `dev.cfg` updated with correct values for variables and configurations.
```
terraform init -backend-config='/backends/dev.cfg'
terraform plan -var-file='env.tfvars' -out='my.tfplan'
terraform apply my.tfplan
```

For local runs with local configs and vars with values (not commited `env.local.tfvars` and `dev.local.cfg`).
```
terraform init -backend-config='/backends/dev.local.cfg'
terraform plan -var-file='env.local.tfvars' -out='my.tfplan'
terraform apply my.tfplan
```