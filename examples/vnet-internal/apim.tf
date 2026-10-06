locals {
  apim = {
    name                = module.naming.api_management.name_unique
    resource_group_name = module.rg.groups.demo.name
    location            = module.rg.groups.demo.location
    sku_name            = "Developer_1"
    publisher_name      = "codectl"
    publisher_email     = "testuser@codectl.nl"

    virtual_network_type = "Internal"
    virtual_network_configuration = {
      subnet_id = module.vnet.subnets.sn1.id
    }
  }
}

