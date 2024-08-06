resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "default" {
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names    = [var.domain]
  ip_addresses = [google_compute_address.default.address]

  subject {
    common_name  = var.domain
    organization = var.project_id
  }

  validity_period_hours = 17280
  is_ca_certificate     = false
  private_key_pem       = tls_private_key.default.private_key_pem
}
