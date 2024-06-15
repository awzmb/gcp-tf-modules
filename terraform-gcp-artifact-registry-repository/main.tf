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
  source  = "GoogleCloudPlatform/artifact-registry/google"
  version = "~> 0.2"

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
