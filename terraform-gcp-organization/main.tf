terraform {
  required_version = ">=1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.25.0, < 6"
    }
  }
}

data "google_organization" "organization" {
  domain = var.domain
}

#module "subfolders" {
#count   = length(var.subfolders) == 0 ? 0 : 1

#source  = "terraform-google-modules/folders/google"
#version = "~> 4.0"

#parent = "folders/65552901371"

#names = [
#"dev",
#"staging",
#"production",
#]

#set_roles = true

##per_folder_admins = {
##dev        = "group:gcp-developers@domain.com"
##staging    = "group:gcp-qa@domain.com"
##production = "group:gcp-ops@domain.com"
##}

#all_folder_admins = [
#"group:gcp-security@domain.com",
#]
#}
