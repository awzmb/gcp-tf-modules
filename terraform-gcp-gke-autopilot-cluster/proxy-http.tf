# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_backend_service
resource "google_compute_region_backend_service" "http" {
  count = var.proxy_mode == "HTTP" ? 1 : 0

  name    = local.http_backend_service_name
  project = google_compute_subnetwork.default.project
  region  = var.region

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
    google_compute_region_health_check.default[0].id
  ]
}

# https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/compute_health_check
#resource "google_compute_health_check" "default" {
#name    = "${local.gke_cluster_name}-l7-xlb-basic-check-http"
#project = google_compute_subnetwork.default.project
#region  = google_compute_subnetwork.default.region

#region_health_check {
#port_specification = "USE_SERVING_PORT"
#request_path       = "/"
#}

#timeout_sec         = 1
#check_interval_sec  = 3
#healthy_threshold   = 1
#unhealthy_threshold = 1

#depends_on = [
#google_compute_firewall.default
#]
#}

resource "google_compute_forwarding_rule" "redirect" {
  count = var.proxy_mode == "HTTP" ? 1 : 0

  name        = "${local.gke_cluster_name}-layer7--xlb-forwarding-rule-http-redirect"
  project     = google_compute_subnetwork.default.project
  region      = google_compute_subnetwork.default.region
  ip_protocol = "TCP"

  # scheme required for a external http load balancer. this uses an external managed envoy proxy
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.redirect[0].id
  network               = google_compute_network.default.id
  ip_address            = google_compute_address.default.id
  network_tier          = "STANDARD"

  depends_on = [
    google_compute_subnetwork.proxy
  ]
}

resource "google_compute_forwarding_rule" "https" {
  count = var.proxy_mode == "HTTP" ? 1 : 0

  name        = "${local.gke_cluster_name}-layer7--xlb-forwarding-rule-https"
  project     = google_compute_subnetwork.default.project
  region      = google_compute_subnetwork.default.region
  ip_protocol = "TCP"

  # scheme required for a external https load balancer. this uses an external managed envoy proxy
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_region_target_https_proxy.default[0].id
  network               = google_compute_network.default.id
  ip_address            = google_compute_address.default.id
  network_tier          = "STANDARD"

  depends_on = [
    google_compute_subnetwork.proxy
  ]
}

resource "google_compute_region_target_http_proxy" "redirect" {
  count = var.proxy_mode == "HTTP" ? 1 : 0

  name    = "${local.gke_cluster_name}-layer7--xlb-proxy-http-redirect"
  project = google_compute_subnetwork.default.project
  region  = google_compute_subnetwork.default.region
  url_map = google_compute_region_url_map.redirect[0].id
}

resource "google_compute_region_url_map" "redirect" {
  count = var.proxy_mode == "HTTP" ? 1 : 0

  name    = "${local.gke_cluster_name}-layer7--xlb-map-http-redirect"
  project = google_compute_subnetwork.default.project
  region  = google_compute_subnetwork.default.region

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_region_url_map" "default" {
  count = var.proxy_mode == "HTTP" ? 1 : 0

  name            = "${local.gke_cluster_name}-url-map"
  default_service = google_compute_region_backend_service.http[0].id
  region          = google_compute_subnetwork.default.region

  host_rule {
    hosts        = [data.google_dns_managed_zone.dns_zone.dns_name]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_region_backend_service.http[0].id

    path_rule {
      paths   = ["/*"]
      service = google_compute_region_backend_service.http[0].id
    }
  }
}

resource "google_compute_region_health_check" "default" {
  count = var.proxy_mode == "HTTP" ? 1 : 0

  name    = "${local.gke_cluster_name}-http-health-check"
  project = google_compute_subnetwork.default.project
  region  = google_compute_subnetwork.default.region

  timeout_sec        = 1
  check_interval_sec = 1

  tcp_health_check {
    port = "80"
  }
}

resource "google_compute_region_ssl_certificate" "default" {
  count = var.proxy_mode == "HTTP" ? 1 : 0

  name        = "${local.gke_cluster_name}-xlb-certificate"
  description = "SSL certificate for layer7--xlb-proxy-https"
  project     = google_compute_subnetwork.default.project
  region      = var.region

  certificate = tls_self_signed_cert.default[0].cert_pem
  private_key = tls_private_key.default[0].private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}

# https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/compute_ssl_certificate#example-usage---ssl-certificate-target-https-proxies
resource "google_compute_region_target_https_proxy" "default" {
  count = var.proxy_mode == "HTTP" ? 1 : 0

  name    = "${local.gke_cluster_name}-layer7--xlb-proxy-https"
  project = google_compute_subnetwork.default.project
  region  = google_compute_subnetwork.default.region
  url_map = google_compute_region_url_map.default[0].id

  ssl_certificates = [
    google_compute_region_ssl_certificate.default[0].id
  ]
}
