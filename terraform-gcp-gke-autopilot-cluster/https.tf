data "google_dns_managed_zone" "dns_zone" {
  name = var.dns_zone_name
}

resource "google_compute_forwarding_rule" "redirect" {
  name        = "${local.gke_cluster_name}-layer7--xlb-forwarding-rule-http-redirect"
  project     = google_compute_subnetwork.default.project
  region      = google_compute_subnetwork.default.region
  ip_protocol = "TCP"

  # scheme required for a regional external http load balancer. this uses an external managed envoy proxy
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.redirect.id
  network               = google_compute_network.default.id
  ip_address            = google_compute_address.default.id
  network_tier          = "STANDARD"

  depends_on = [
    google_compute_subnetwork.proxy
  ]
}

resource "google_compute_forwarding_rule" "https" {
  name        = "${local.gke_cluster_name}-layer7--xlb-forwarding-rule-https"
  project     = google_compute_subnetwork.default.project
  region      = google_compute_subnetwork.default.region
  ip_protocol = "TCP"

  # scheme required for a regional external https load balancer. this uses an external managed envoy proxy
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.default.id
  network               = google_compute_network.default.id
  ip_address            = google_compute_address.default.id
  network_tier          = "STANDARD"

  depends_on = [
    google_compute_subnetwork.proxy
  ]
}

resource "google_compute_region_target_http_proxy" "redirect" {
  name    = "${local.gke_cluster_name}-layer7--xlb-proxy-http-redirect"
  project = google_compute_subnetwork.default.project
  region  = google_compute_subnetwork.default.region
  url_map = google_compute_url_map.redirect.id
}

resource "google_compute_url_map" "redirect" {
  name    = "${local.gke_cluster_name}-regional-layer7--xlb-map-http-redirect"
  project = google_compute_subnetwork.default.project

  default_url_redirect {
    https_redirect = true
    strip_query    = false
  }
}

resource "google_compute_url_map" "default" {
  name            = "${local.gke_cluster_name}-url-map"
  default_service = google_compute_region_backend_service.default.id

  host_rule {
    hosts        = [data.google_dns_managed_zone.dns_zone.dns_name]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_region_backend_service.default.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_region_backend_service.default.id
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
