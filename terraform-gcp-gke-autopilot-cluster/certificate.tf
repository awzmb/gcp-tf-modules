# this creates a new self-signed certificate for the domain
# and the external IP address of the load balancer. this is
# only used for communication between the load balancer and
# the envoy proxy not for the actual domain.
resource "tls_private_key" "default" {
  count = var.proxy_mode == "TCP" ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "default" {
  count = var.proxy_mode == "TCP" ? 1 : 0

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names    = [data.google_dns_managed_zone.dns_zone.dns_name]
  ip_addresses = [google_compute_address.default.address]

  subject {
    common_name  = data.google_dns_managed_zone.dns_zone.dns_name
    organization = var.project_id
  }

  validity_period_hours = 17280
  is_ca_certificate     = false
  private_key_pem       = tls_private_key.default[0].private_key_pem
}
