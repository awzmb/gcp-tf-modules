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

resource "random_id" "suffix" {
  byte_length = 2
}

resource "google_project" "project" {
  name            = var.display_name
  project_id      = "${var.project_id}-${random_id.suffix.hex}"
  billing_account = var.billing_account_id

  auto_create_network = true
}
