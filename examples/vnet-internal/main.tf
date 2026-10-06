module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "vnet" {
  source  = "codectl/vnet/azure"
  version = "~> 1.0"

  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.0.0.0/16"]
    subnets = {
      sn1 = {
        address_prefixes = ["10.0.0.0/24"]
        network_security_group = {
          rules = local.apim_nsg_rules
        }
      }
    }
  }
}

module "apim" {
  source  = "codectl/apim/azure"
  version = "~> 1.0"

  service = local.apim

  depends_on = [module.vnet]
}
