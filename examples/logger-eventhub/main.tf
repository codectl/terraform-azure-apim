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

module "eventhub" {
  source  = "codectl/evh/azure"
  version = "~> 1.0"

  namespace = {
    name                = module.naming.eventhub_namespace.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    eventhubs = {
      apim = {
        authorization_rules = {
          send = {
            send = true
          }
        }
      }
    }
  }
}

module "apim" {
  source  = "codectl/apim/azure"
  version = "~> 1.0"

  service = {
    name                = module.naming.api_management.name_unique
    resource_group_name = module.rg.groups.demo.name
    location            = module.rg.groups.demo.location
    sku_name            = "Developer_1"
    publisher_name      = "codectl"
    publisher_email     = "testuser@codectl.nl"

    logger = {
      name        = "evh-logger"
      description = "event hub logger"
      buffered    = false

      eventhub = {
        name              = module.eventhub.eventhubs.apim.name
        connection_string = module.eventhub.authorization_rules["apim-send"].primary_connection_string
      }
    }
  }
}
