resource "google_service_account" "gke_node" {
  account_id   = "${local.gke_cluster_name}-node-sa"
  display_name = "GKE Node Service Account for ${local.gke_cluster_name}"
}

resource "google_project_iam_member" "gke_node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.objectViewer",
  ])

  project = var.project_id
  member  = "serviceAccount:${google_service_account.gke_node.email}"
  role    = each.value
}
