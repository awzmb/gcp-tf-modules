data "google_dns_managed_zone" "dns_zone" {
  name = var.dns_zone_name
}
resource "google_compute_subnetwork" "proxy" {
  #checkov:skip=CKV_GCP_76:private access is enabled
  #checkov:skip=CKV_GCP_74:not relevant in proxy-only subnet
  #checkov:skip=CKV_GCP_26:VPC flow logs are not necessary in this context

  provider = google-beta
  name     = "${var.project_id}-proxy-only-subnet"

  ip_cidr_range = local.proxy_only_ipv4_cidr
  project       = google_compute_network.default.project
  network       = google_compute_network.default.id
  #region        = var.region

  #purpose = "REGIONAL_MANAGED_PROXY"
  purpose = "GLOBAL_MANAGED_PROXY"
  role    = "ACTIVE"

  depends_on = [
    google_compute_network.default
  ]
}

#data "google_compute_network_endpoint_group" "neg_http" {
#name    = local.istio_ingress_gateway_endpoint_group_http
#project = var.project_id

#depends_on = [
#helm_release.istio_gateway
#]
#}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service
resource "google_compute_backend_service" "default" {
  name    = local.http_backend_service_name
  project = google_compute_subnetwork.default.project
  #region  = var.region

  protocol    = "HTTP"
  timeout_sec = 10

  # scheme required for a external http load balancer. this uses an external managed envoy proxy
  load_balancing_scheme = "EXTERNAL_MANAGED"

  #backend {
  #group           = data.google_compute_network_endpoint_group.neg_http.id
  #capacity_scaler = 1
  #balancing_mode  = "RATE"

  ## this is a reasonable max rate for an envoy proxy
  #max_rate_per_endpoint = 3500
  #}

  health_checks = [
    google_compute_health_check.default.id
  ]
}

# https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/compute_health_check
resource "google_compute_health_check" "default" {
  name    = "${local.gke_cluster_name}-l7-xlb-basic-check-http"
  project = google_compute_subnetwork.default.project
  #region  = google_compute_subnetwork.default.region

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

resource "google_compute_global_forwarding_rule" "redirect" {
  name    = "${local.gke_cluster_name}-layer7--xlb-forwarding-rule-http-redirect"
  project = google_compute_subnetwork.default.project
  #region      = google_compute_subnetwork.default.region
  ip_protocol = "TCP"

  # scheme required for a external http load balancer. this uses an external managed envoy proxy
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.redirect.id
  #network               = google_compute_network.default.id
  ip_address = google_compute_address.default.id
  #network_tier          = "STANDARD"

  depends_on = [
    google_compute_subnetwork.proxy
  ]
}

resource "google_compute_global_forwarding_rule" "https" {
  name    = "${local.gke_cluster_name}-layer7--xlb-forwarding-rule-https"
  project = google_compute_subnetwork.default.project
  #region      = google_compute_subnetwork.default.region
  ip_protocol = "TCP"

  # scheme required for a external https load balancer. this uses an external managed envoy proxy
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.default.id
  #network               = google_compute_network.default.id
  ip_address = google_compute_address.default.id
  #network_tier          = "STANDARD"

  depends_on = [
    google_compute_subnetwork.proxy
  ]
}

resource "google_compute_target_http_proxy" "redirect" {
  name    = "${local.gke_cluster_name}-layer7--xlb-proxy-http-redirect"
  project = google_compute_subnetwork.default.project
  #region  = google_compute_subnetwork.default.region
  url_map = google_compute_url_map.redirect.id
}

resource "google_compute_url_map" "redirect" {
  name    = "${local.gke_cluster_name}-layer7--xlb-map-http-redirect"
  project = google_compute_subnetwork.default.project

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_url_map" "default" {
  name            = "${local.gke_cluster_name}-url-map"
  default_service = google_compute_backend_service.default.id

  host_rule {
    hosts        = [data.google_dns_managed_zone.dns_zone.dns_name]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.default.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.default.id
    }
  }
}

resource "google_compute_http_health_check" "default" {
  name               = "${local.gke_cluster_name}-http-health-check"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_managed_ssl_certificate" "default" {
  name        = "${local.gke_cluster_name}-certificate"
  description = "SSL certificate for layer7--xlb-proxy-https"
  project     = google_compute_subnetwork.default.project

  lifecycle {
    create_before_destroy = true
  }

  managed {
    domains = [data.google_dns_managed_zone.dns_zone.dns_name]
  }
}

# https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/compute_ssl_certificate#example-usage---ssl-certificate-target-https-proxies
resource "google_compute_target_https_proxy" "default" {
  name    = "${local.gke_cluster_name}-layer7--xlb-proxy-https"
  project = google_compute_subnetwork.default.project
  url_map = google_compute_url_map.default.id

  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.id
  ]

  depends_on = [
    google_compute_managed_ssl_certificate.default
  ]
}
