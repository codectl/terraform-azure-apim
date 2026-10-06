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

module "kv" {
  source  = "codectl/kv/azure"
  version = "~> 1.0"

  vault = {
    name                = module.naming.key_vault.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    certs = local.certs
  }
}

module "uai" {
  source  = "codectl/uai/azure"
  version = "~> 1.0"

  identity = {
    name                = module.naming.user_assigned_identity.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

resource "azurerm_role_assignment" "kv" {
  scope                = module.kv.vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.uai.identity.principal_id
}

module "apim" {
  source  = "codectl/apim/azure"
  version = "~> 1.0"

  service = local.apim

  depends_on = [azurerm_role_assignment.kv]
}
