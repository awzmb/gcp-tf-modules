terraform {
  required_version = ">=1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.25.0, < 6"
    }
  }
}

data "google_project" "project" {
}

resource "google_project_service" "domain" {
  service            = "domains.googleapis.com"
  disable_on_destroy = false
  project            = data.google_project.project.number
}

resource "google_clouddomains_registration" "registration" {
  domain_name = var.domain_name
  location    = "global"

  domain_notices = ["HSTS_PRELOADED"]
  #domain_notices = ["DOMAIN_NOTICE_UNSPECIFIED"]

  yearly_price {
    currency_code = var.pricing_currency_code
    units         = var.pricing_yearly_price
  }

  dns_settings {
    custom_dns {
      name_servers = var.name_servers
    }
  }

  contact_settings {
    privacy = "REDACTED_CONTACT_DATA"

    registrant_contact {
      phone_number = var.phone_number
      email        = var.email_address

      postal_address {
        recipients          = [var.contact_name]
        organization        = var.organization
        region_code         = var.region_code
        postal_code         = var.postal_code
        administrative_area = var.administrative_area
        locality            = var.city
        address_lines       = [var.address]
      }
    }

    admin_contact {
      phone_number = var.phone_number
      email        = var.email_address

      postal_address {
        recipients          = [var.contact_name]
        organization        = var.organization
        region_code         = var.region_code
        postal_code         = var.postal_code
        administrative_area = var.administrative_area
        locality            = var.city
        address_lines       = [var.address]
      }
    }

    technical_contact {
      phone_number = var.phone_number
      email        = var.email_address

      postal_address {
        recipients          = [var.contact_name]
        organization        = var.organization
        region_code         = var.region_code
        postal_code         = var.postal_code
        administrative_area = var.administrative_area
        locality            = var.city
        address_lines       = [var.address]
      }
    }
  }

  lifecycle {
    ignore_changes = [
      dns_settings
    ]
  }

  depends_on = [
    google_project_service.domain
  ]
}
