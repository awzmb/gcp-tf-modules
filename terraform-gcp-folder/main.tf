terraform {
  required_version = ">=1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.25.0, < 6"
    }
  }
}

resource "google_folder" "folder" {
  display_name = var.display_name
  parent       = var.parent
}

output "folder_id" {
  value = google_folder.folder.name
}
