provider "google" {
  project = "awzm-dev-ed85"
}

terraform {
	required_providers {
		google = {
	    version = "~> 5.33.0"
		}
  }
}
