# This solution deploys a Regional External HTTP Load Balancer that routes traffic from the Internet to
# the ingress gateway for the GKE Cluster. The Regional External HTTP Load Balancer uses Envoy as a
# managed proxy deployment. More information on the Regional External HTTP Load Balancer can be found here:
# https://cloud.google.com/load-balancing/docs/https#regional-connections

# Subnet reserved for Regional External HTTP Load Balancers that use a managed Envoy proxy.
# More information is available here: https://cloud.google.com/load-balancing/docs/https/proxy-only-subnets
resource "google_compute_subnetwork" "proxy" {
  #checkov:skip=CKV_GCP_76:private access is enabled
  #checkov:skip=CKV_GCP_26:VPC flow logs are not necessary in this context

  provider = google-beta
  name     = "${var.project_id}-proxy-only-subnet"

  ip_cidr_range = local.proxy_only_ipv4_cidr
  project       = google_compute_network.default.project
  region        = var.region
  network       = google_compute_network.default.id

  purpose = "REGIONAL_MANAGED_PROXY"
  role    = "ACTIVE"

  depends_on = [
    google_compute_network.default
  ]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_backend_service
resource "google_compute_region_backend_service" "default" {
  name        = "${local.gke_cluster_name}-l7-xlb-backend-service-http"
  project     = google_compute_subnetwork.default.project
  region      = google_compute_subnetwork.default.region
  protocol    = "HTTP"
  timeout_sec = 10

  # scheme required for a regional external http load balancer. this uses an external managed envoy proxy
  load_balancing_scheme = "EXTERNAL_MANAGED"

  health_checks = [
    google_compute_region_health_check.default.id
  ]

  #backend {
  #group           = "https://www.googleapis.com/compute/v1/projects/${var.project_id}/region/${var.region}/networkEndpointGroups/ingressgateway"
  #capacity_scaler = 1
  #balancing_mode  = "RATE"

  ## this is a reasonable max rate for an envoy proxy
  #max_rate_per_endpoint = 3500
  #}

  circuit_breakers {
    max_retries = 5
  }

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
  #depends_on = [
  #helm_release.istio_gateway
  #]
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

  # required to be standard for use with regional_managed_proxy
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
