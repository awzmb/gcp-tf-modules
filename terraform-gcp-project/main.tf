terraform {
  required_version = ">=1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.25.0, < 6"
    }
  }
}

resource "google_project" "project" {
  #checkov:skip=CKV2_GCP_5:not a professional setup
  #checkov:skip=CKV_GCP_27:not a professional setup
  name       = var.display_name
  project_id = var.display_name

  auto_create_network = true
}
