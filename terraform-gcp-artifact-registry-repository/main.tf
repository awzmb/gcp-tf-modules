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

module "artifact_registry" {
  #version = 0.2.0
  source = "git::https://github.com/googlecloudplatform/terraform-google-artifact-registry?ref=b16d7c7d95c12d59a6d1e70e2162bd0260b99676"

  project_id    = data.google_project.project.number
  location      = var.location
  format        = var.format
  repository_id = var.repository_id

  cleanup_policies = {
    condition = {
      tag_prefixes = ["release", "dev"]
    }

    most_recent_versions = {
      keep_count = 10
    }
  }
}
