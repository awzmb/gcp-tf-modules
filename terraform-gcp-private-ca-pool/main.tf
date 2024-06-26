terraform {
  required_version = ">=1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.25.0, < 6"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.25.0, < 6"
    }
  }
}

resource "google_privateca_ca_pool" "default" {
  name     = var.name
  location = var.region

  tier = var.tier

  publishing_options {
    publish_ca_cert = false
    publish_crl     = true
    encoding_format = "PEM"
  }

  issuance_policy {
    #maximum_lifetime = "50000s"

    allowed_key_types {
      elliptic_curve {
        signature_algorithm = "ECDSA_P256"
      }
    }

    allowed_key_types {
      rsa {
        min_modulus_size = 5
        max_modulus_size = 10
      }
    }


    allowed_issuance_modes {
      allow_csr_based_issuance    = true
      allow_config_based_issuance = true
    }

    identity_constraints {
      allow_subject_passthrough           = true
      allow_subject_alt_names_passthrough = true

      # https://cloud.google.com/certificate-authority-service/docs/cel-guide
      cel_expression {
        expression = "subject_alt_names.all(san, san.type == DNS || san.type == EMAIL )"
      }
    }

    baseline_values {
      aia_ocsp_servers = [var.domain]

      policy_ids {
        object_id_path = [1, 5]
      }

      policy_ids {
        object_id_path = [1, 5, 7]
      }

      ca_options {
        is_ca                  = true
        max_issuer_path_length = 10
      }

      key_usage {
        base_key_usage {
          digital_signature  = true
          content_commitment = true
          key_encipherment   = false
          data_encipherment  = true
          key_agreement      = true
          cert_sign          = false
          crl_sign           = true
          decipher_only      = true
        }

        extended_key_usage {
          server_auth      = true
          client_auth      = false
          email_protection = true
          code_signing     = true
          time_stamping    = true
        }
      }

      name_constraints {
        critical            = true
        permitted_dns_names = ["*.${var.domain}"]
        #permitted_ip_ranges       = ["10.0.0.0/8", "11.0.0.0/8"]
        #excluded_ip_ranges        = ["10.1.1.0/24", "11.1.1.0/24"]
        #permitted_email_addresses = [".example1.com", ".example2.com"]
        #excluded_email_addresses  = [".deny.example1.com", ".deny.example2.com"]
        permitted_uris = [".${var.domain}"]
        #excluded_uris  = [".deny.example1.com", ".deny.example2.com"]
      }
    }
  }
}
