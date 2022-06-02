###################################################
########## GENERATING CERTIFICATE #################
###################################################

terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.0"
    }
  }
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

# Creates a private key in PEM format
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

# Creates an account on the ACME server using the private key and an email
resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  #email_address   = 
}

# As the certificate will be generated in PFX a password is required
resource "random_password" "cert" {
  length  = 24
  special = true
}

# Gets a certificate from the ACME server
resource "acme_certificate" "cert" {
  account_key_pem          = acme_registration.reg.account_key_pem
  #common_name              =  # The hostname goes here
  certificate_p12_password = random_password.cert.result

  dns_challenge {
    provider = "azure"

    config = {
      AZURE_RESOURCE_GROUP = "cordsResourceGroupAG"
      AZURE_ZONE_NAME      = "test.dummycordsfun.com"
      AZURE_TTL            = 300
    }
  }
}

# resource "azurerm_app_service_certificate" "cert" {
#   name                = "acme"
#   resource_group_name = "cordsResourceGroupAG"
#   location            = "centralus"

#   pfx_blob = acme_certificate.cert.certificate_p12
#   password = acme_certificate.cert.certificate_p12_password
# } 