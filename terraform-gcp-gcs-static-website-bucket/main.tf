terraform {
  required_version = ">=1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.25.0, < 6"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.25.0, < 6"
    }
  }
}

resource "google_storage_bucket" "static_website" {
  name          = var.bucket_name
  location      = var.region
  storage_class = var.storage_class
  force_destroy = var.force_destroy

  website {
    main_page_suffix = var.index_page
    not_found_page   = var.error_page
  }

  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_member" "all_users" {
  bucket = google_storage_bucket.static_website.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}
