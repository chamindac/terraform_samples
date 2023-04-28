This terraform code shows how to add virtual network rule dynamically to Azure coginitive account based on env variable value.

```
dynamic "virtual_network_rules" {
    for_each = var.env == "dev" ? [1] : []
    content {
    subnet_id = azurerm_subnet.aks_snet.id
    }
}
```

Complete code block of conginive account

```
resource "azurerm_cognitive_account" "ca" {
  name                  = "cs-cognitive-test01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  kind                  = "TextTranslation"
  custom_subdomain_name = "cs-cognitive-test01"

  sku_name = "F0"

  network_acls {
    default_action = "Deny"

    virtual_network_rules {
      subnet_id = azurerm_subnet.vm_snet.id
    }

    dynamic "virtual_network_rules" {
      for_each = var.env == "dev" ? [1] : []
      content {
        subnet_id = azurerm_subnet.aks_snet.id
      }
    }
  }
}
```

If env is dev then two subnets get added to the cognitive account allowed subnets.
`terraform apply -var='env=dev'`
![image](https://user-images.githubusercontent.com/20109548/235071594-baf100b8-2943-4b88-a2b6-98d5a894309d.png)

If env is not dev then only one subnet get added to the cognitive account allowed subnets.
`terraform apply -var='env=prod'`
![image](https://user-images.githubusercontent.com/20109548/235071669-73e3d382-4a22-4da2-b14c-a144c0d8137b.png)
