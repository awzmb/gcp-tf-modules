terraform {
  required_version = ">=1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.25.0, < 6"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

locals {
  google_apis_to_enable = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "monitoring.googleapis.com"
  ]
}

resource "random_id" "suffix" {
  byte_length = 2
}

#data "google_billing_account" "biling_account" {
#display_name = "General billing account"
#open         = true
#}

resource "google_project" "project" {
  name       = var.display_name
  project_id = "${var.project_id}-${random_id.suffix.hex}"

  billing_account = var.billing_account_id
  #billing_account = data.google_billing_account.billing_account.id

  auto_create_network = true
}

resource "google_project_service" "enable_selected_apis" {
  for_each           = toset(local.google_apis_to_enable)
  service            = each.key
  disable_on_destroy = false
  project            = google_project.project.project_id
}
