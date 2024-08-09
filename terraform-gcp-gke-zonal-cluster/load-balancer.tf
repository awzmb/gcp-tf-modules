resource "google_compute_subnetwork" "proxy" {
  #checkov:skip=CKV_GCP_76:private access is enabled
  #checkov:skip=CKV_GCP_74:not relevant in proxy-only subnet
  #checkov:skip=CKV_GCP_26:VPC flow logs are not necessary in this context

  provider = google-beta
  name     = "${var.project_id}-proxy-only-subnet"

  ip_cidr_range = local.proxy_only_ipv4_cidr
  project       = google_compute_network.default.project
  network       = google_compute_network.default.id
  region        = var.region

  purpose = "REGIONAL_MANAGED_PROXY"
  role    = "ACTIVE"

  depends_on = [
    google_compute_network.default
  ]
}

# get the endpoint group of the istio gateway
data "google_compute_network_endpoint_group" "neg_http" {
  name    = local.istio_ingress_gateway_endpoint_group_http
  project = var.project_id
  zone    = var.zone

  depends_on = [
    module.istio
  ]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_backend_service
resource "google_compute_region_backend_service" "default" {
  name    = "${local.gke_cluster_name}-l7-xlb-backend-service-http"
  project = google_compute_subnetwork.default.project

  protocol    = "HTTP"
  timeout_sec = 10

  # scheme required for a regional external http load balancer. this uses an external managed envoy proxy
  load_balancing_scheme = "EXTERNAL_MANAGED"

  health_checks = [
    google_compute_region_health_check.default.id
  ]

  backend {
    group           = data.google_compute_network_endpoint_group.neg_http.id
    capacity_scaler = 1
    balancing_mode  = "RATE"

    # this is a reasonable max rate for an envoy proxy
    max_rate_per_endpoint = 3500
  }

  #circuit_breakers {
  #max_retries = 5
  #}

  outlier_detection {
    consecutive_errors = 2

    base_ejection_time {
      seconds = 30
    }

    interval {
      seconds = 2
    }

    max_ejection_percent = 50
  }

  # this cannot be deployed until the ingress gateway is deployed and the standalone neg is automatically created
  depends_on = [
    module.istio
  ]
}

# https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/compute_region_health_check
resource "google_compute_region_health_check" "default" {
  name    = "${local.gke_cluster_name}-l7-xlb-basic-check-http"
  project = google_compute_subnetwork.default.project
  region  = google_compute_subnetwork.default.region

  http_health_check {
    port_specification = "USE_SERVING_PORT"
    request_path       = "/"
  }

  timeout_sec         = 1
  check_interval_sec  = 3
  healthy_threshold   = 1
  unhealthy_threshold = 1

  depends_on = [
    google_compute_firewall.default
  ]
}

resource "google_compute_address" "default" {
  name    = "${local.gke_cluster_name}-ip-address"
  project = google_compute_subnetwork.default.project
  region  = google_compute_subnetwork.default.region

  # required to be standard for use with regional proxy
  network_tier = "STANDARD"
}

resource "google_compute_firewall" "default" {
  name    = "${local.gke_cluster_name}-fw-allow-health-check-and-proxy"
  network = google_compute_network.default.id
  project = google_compute_network.default.project
  # allow for ingress from the health checks and the managed envoy proxy. for more information, see:
  # https://cloud.google.com/load-balancing/docs/https#target-proxies
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", local.proxy_only_ipv4_cidr]

  allow {
    protocol = "tcp"
  }

  target_tags = [
    local.gke_cluster_name
  ]

  direction = "INGRESS"
}
