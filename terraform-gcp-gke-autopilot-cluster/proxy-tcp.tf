# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_backend_service
resource "google_compute_region_backend_service" "tcp" {
  count = var.proxy_mode == "TCP" ? 1 : 0

  name    = local.http_backend_service_name
  project = google_compute_subnetwork.default.project
  region  = var.region

  protocol    = "TCP"
  timeout_sec = 10

  # scheme required for a external http load balancer. this uses an external managed envoy proxy
  load_balancing_scheme = "EXTERNAL_MANAGED"

  health_checks = [
    google_compute_region_health_check.tcp_http[0].id
  ]
}

resource "google_compute_region_health_check" "tcp_http" {
  count = var.proxy_mode == "TCP" ? 1 : 0

  name    = "${local.gke_cluster_name}-http-health-check"
  project = google_compute_subnetwork.default.project
  region  = google_compute_subnetwork.default.region

  timeout_sec         = 5
  check_interval_sec  = 5
  healthy_threshold   = 3
  unhealthy_threshold = 3

  tcp_health_check {
    port = "80"
  }
}

resource "google_compute_region_target_tcp_proxy" "tcp_target_proxy" {
  name            = "${local.gke_cluster_name}-tcp-target-proxy"
  project         = google_compute_subnetwork.default.project
  region          = google_compute_subnetwork.default.region
  backend_service = google_compute_region_backend_service.tcp[0].id
}

resource "google_compute_forwarding_rule" "tcp_http" {
  count = var.proxy_mode == "TCP" ? 1 : 0

  name        = "${local.gke_cluster_name}-layer7--xlb-forwarding-rule-tcp-80"
  project     = google_compute_subnetwork.default.project
  region      = google_compute_subnetwork.default.region
  ip_protocol = "TCP"

  # scheme required for a external http load balancer. this uses an external managed envoy proxy
  load_balancing_scheme = "EXTERNAL_MANAGED"

  port_range = "80"

  target       = google_compute_region_target_tcp_proxy.tcp_target_proxy.id
  network      = google_compute_network.default.id
  ip_address   = google_compute_address.default.id
  network_tier = "STANDARD"

  depends_on = [
    google_compute_subnetwork.proxy
  ]
}

resource "google_compute_forwarding_rule" "tcp_https" {
  count = var.proxy_mode == "TCP" ? 1 : 0

  name        = "${local.gke_cluster_name}-layer7--xlb-forwarding-rule-tcp-443"
  project     = google_compute_subnetwork.default.project
  region      = google_compute_subnetwork.default.region
  ip_protocol = "TCP"

  # scheme required for a external https load balancer. this uses an external managed envoy proxy
  load_balancing_scheme = "EXTERNAL_MANAGED"

  port_range = "443"

  target       = google_compute_region_target_tcp_proxy.tcp_target_proxy.id
  network      = google_compute_network.default.id
  ip_address   = google_compute_address.default.id
  network_tier = "STANDARD"

  depends_on = [
    google_compute_subnetwork.proxy
  ]
}
