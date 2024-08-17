resource "google_dns_record_set" "http_record" {
  name         = "${data.google_dns_managed_zone.dns_zone.dns_name}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.dns_zone.name

  rrdatas = [
    var.proxy_mode == "TCP" ?
    google_compute_forwarding_rule.tcp_http[0].ip_address :
    google_compute_forwarding_rule.redirect[0].ip_address
  ]
}

resource "google_dns_record_set" "http_wildcard_record" {
  name         = "*.${data.google_dns_managed_zone.dns_zone.dns_name}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.dns_zone.name

  rrdatas = [
    var.proxy_mode == "TCP" ?
    google_compute_forwarding_rule.tcp_http[0].ip_address :
    google_compute_forwarding_rule.redirect[0].ip_address
  ]
}

resource "google_dns_record_set" "https_record" {
  name         = "${data.google_dns_managed_zone.dns_zone.dns_name}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.dns_zone.name

  rrdatas = [
    var.proxy_mode == "TCP" ?
    google_compute_forwarding_rule.tcp_https[0].ip_address :
    google_compute_forwarding_rule.https[0].ip_address
  ]
}

resource "google_dns_record_set" "https_wildcard_record" {
  name         = "*.${data.google_dns_managed_zone.dns_zone.dns_name}."
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.dns_zone.name

  rrdatas = [
    var.proxy_mode == "TCP" ?
    google_compute_forwarding_rule.tcp_https[0].ip_address :
    google_compute_forwarding_rule.https[0].ip_address
  ]
}
