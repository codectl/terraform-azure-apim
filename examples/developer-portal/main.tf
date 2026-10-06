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

data "azurerm_client_config" "current" {}

resource "random_password" "delegation" {
  length  = 64
  special = false
}

resource "random_password" "aad" {
  length  = 32
  special = false
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

    delegation = {
      subscriptions_enabled     = true
      user_registration_enabled = false
      url                       = "https://delegation.example.com"
      validation_key            = base64encode(random_password.delegation.result)
    }

    sign_in = {
      enabled = true
    }

    sign_up = {
      enabled = true

      terms_of_service = {
        enabled          = true
        consent_required = true
        text             = "By signing up you agree to the terms of service."
      }
    }

    identity_provider_aad = {
      client_id       = "00000000-0000-0000-0000-000000000000"
      client_secret   = random_password.aad.result
      allowed_tenants = [data.azurerm_client_config.current.tenant_id]
      signin_tenant   = data.azurerm_client_config.current.tenant_id
      client_library  = "MSAL-2"
    }
  }
}
