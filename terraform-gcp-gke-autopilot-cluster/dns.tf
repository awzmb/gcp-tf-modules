resource "google_dns_record_set" "record" {
  name         = data.google_dns_managed_zone.dns_zone.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.dns_zone.name

  rrdatas = [google_compute_address.default.address]
}

resource "google_dns_record_set" "wildcard_record" {
  name         = "*.${data.google_dns_managed_zone.dns_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.dns_zone.name

  rrdatas = [google_compute_address.default.address]
}
