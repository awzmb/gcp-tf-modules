terraform {
  required_version = ">=1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.25.0, < 6"
    }
  }
}

resource "google_dns_managed_zone" "zone" {
  name        = var.zone_name
  dns_name    = "${var.dns_zone}."
  description = "Cloud DNS zone for ${var.dns_zone}"

  dnssec_config {
    state = "on"
  }

  labels = var.labels
}
