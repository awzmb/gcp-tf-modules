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

resource "google_dns_record_set" "dns_records" {
  for_each = var.dns_records

  managed_zone = google_dns_managed_zone.zone.name
  name         = each.value.name
  type         = each.value.type
  ttl          = each.value.ttl
  rrdatas      = each.value.rrdatas
}
