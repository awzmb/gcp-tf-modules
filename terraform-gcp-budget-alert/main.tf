# gcp_budget_alert/main.tf
terraform {
  required_version = ">= 0.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.25.0, < 6"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file_path)
  project     = var.project_id
}

resource "google_billing_budget" "budget" {
  billing_account = var.billing_account_id
  display_name    = var.budget_name

  budget_filter {
    projects = var.project_ids
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = var.budget_amount
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }

  threshold_rules {
    threshold_percent = 0.9
  }

  threshold_rules {
    threshold_percent = 1.0
  }

  all_updates_rule {
    pubsub_topic = google_pubsub_topic.budget_alert.name
  }
}

resource "google_pubsub_topic" "budget_alert" {
  name = "budget-alert-topic"
}

resource "google_pubsub_subscription" "budget_alert_subscription" {
  name  = "budget-alert-subscription"
  topic = google_pubsub_topic.budget_alert.name

  ack_deadline_seconds = 20
  push_config {
    push_endpoint = var.push_endpoint
    attributes = {
      "x-goog-version" = "v1beta1"
    }
  }
}

resource "google_service_account" "pubsub_sa" {
  account_id   = "pubsub-sa"
  display_name = "PubSub Service Account"
}

resource "google_project_iam_member" "pubsub_sa_role" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.pubsub_sa.email}"
}

resource "google_service_account_iam_member" "pubsub_sa_pubsub_role" {
  service_account_id = google_service_account.pubsub_sa.name
  role               = "roles/pubsub.subscriber"
  member             = "serviceAccount:${google_service_account.pubsub_sa.email}"
}

output "pubsub_topic" {
  value = google_pubsub_topic.budget_alert.name
}

output "pubsub_subscription" {
  value = google_pubsub_subscription.budget_alert_subscription.name
}
