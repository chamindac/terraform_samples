Use `az login` to login to Azure with a user
```
az login --service-principal -u APP_ID -p CLIENT_SECRET --tenant TENANT_ID
az account set --subscription <subscriptionid> 
```

Use below comands run terraform
```
terraform init -upgrade
terraform plan -out='my.tfplan'
terraform apply my.tfplan
```