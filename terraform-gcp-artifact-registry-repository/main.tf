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

resource "google_project_service" "enable_artifact_registry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
  project            = data.google_project.project.number
}

#resource "google_kms_crypto_key_iam_member" "crypto_key" {
#crypto_key_id = "${var.location}-${var.repository_id}-encryption-key"
#role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
#member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
#}

resource "google_artifact_registry_repository" "repository" {
  #checkov:skip=CKV_GCP_84:not necessary at the moment
  description = "${var.format} artifact repository."

  project       = data.google_project.project
  location      = var.location
  format        = var.format
  repository_id = var.repository_id

  cleanup_policy_dry_run = true

  #kms_key_name  = "${var.location}-${var.repository_id}-encryption-key"
  #repository_id = "${replace(var.site, ".", "-")}--repository"

  #cleanup_policies {
  #id     = "delete-dev-releases"
  #action = "DELETE"

  #condition {
  #tag_state    = "TAGGED"
  #tag_prefixes = ["dev"]
  #older_than   = "2592000s"
  #}
  #}

  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"

    most_recent_versions {
      keep_count = 3
    }
  }

  #cleanup_policies {
  #id     = "keep-tagged-release"
  #action = "KEEP"

  #condition {
  #tag_state    = "TAGGED"
  #tag_prefixes = ["release"]
  #}
  #}

  depends_on = [
    #google_kms_crypto_key_iam_member.crypto_key,
    google_project_service.enable_artifact_registry
  ]
}

