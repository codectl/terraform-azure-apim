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

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem       = tls_private_key.ca.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 8760

  subject {
    common_name = "demo-root-ca"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
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

    protocols = {
      http2_enabled = true
    }

    security = {
      backend_ssl30_enabled                          = false
      backend_tls10_enabled                          = false
      backend_tls11_enabled                          = false
      frontend_ssl30_enabled                         = false
      frontend_tls10_enabled                         = false
      frontend_tls11_enabled                         = false
      triple_des_ciphers_enabled                     = false
      tls_rsa_with_aes128_gcm_sha256_ciphers_enabled = true
      tls_rsa_with_aes256_gcm_sha384_ciphers_enabled = true
    }

    tenant_access = {
      enabled = false
    }

    certificates = {
      root = {
        store_name = "Root"
        encoded_certificate = replace(
          trimspace(
            replace(
              replace(tls_self_signed_cert.ca.cert_pem, "-----BEGIN CERTIFICATE-----", ""),
              "-----END CERTIFICATE-----", ""
            )
          ), "\n", ""
        )
      }
    }
  }
}
