Use `az login` to login to Azure with a user
```
az login
az account set --subscription <subscriptionid> 
```

Use below comands run terraform
```
terraform init -upgrade
terraform plan -out='my.tfplan'
terraform apply my.tfplan
```