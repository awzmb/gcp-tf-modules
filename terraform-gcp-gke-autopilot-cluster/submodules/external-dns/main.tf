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

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.0, < 3"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30.0, < 3"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.6, < 4"
    }
  }
}

resource "random_id" "random_role_id_suffix" {
  byte_length = 4
}

data "google_client_config" "default" {}

data "google_container_cluster" "default" {
  name     = var.cluster_name
  location = var.region
}

data "google_dns_managed_zone" "dns_zone" {
  name = var.dns_zone_name
}

provider "kubernetes" {
  host                   = data.google_container_cluster.default.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.default.master_auth[0].cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "gke-gcloud-auth-plugin"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.google_container_cluster.default.endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.default.master_auth[0].cluster_ca_certificate)
  }
}

resource "google_service_account" "external_dns" {
  account_id   = "external-dns"
  display_name = "external-dns Service Account"
  project      = var.project_id
}

# custom role to manage DNS records in Cloud DNS
resource "google_project_iam_custom_role" "manage_dns_records" {
  description = "Allows managing DNS records in Cloud DNS."
  permissions = [
    "dns.resourceRecordSets.list", "dns.resourceRecordSets.create", "dns.resourceRecordSets.delete",
    "dns.resourceRecordSets.update", "dns.changes.get", "dns.changes.create", "dns.managedZones.list"
  ]
  project = var.project_id
  role_id = "manage-dns-records-${random_id.random_role_id_suffix.hex}"
  title   = "Manage DNS records"
}

resource "google_project_iam_member" "workload_identity_user_binding" {
  project = var.project_id
  role    = "roles/iam.workloadIdentityUser"
  member  = "serviceAccount:${google_service_account.external_dns.name}.svc.id.goog[external-dns/external-dns]"
}

resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "external-dns"
  }
}

resource "kubernetes_cluster_role" "external_dns" {
  metadata {
    name = "external-dns"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods"]
    verbs      = ["list", "get", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["list", "get", "watch"]
  }

  # give external-dns the ability to watch istio resources
  rule {
    api_groups = ["networking.istio.io"]
    resources  = ["virtualservices", "gateways"]
    verbs      = ["list", "get", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["list", "get"]
  }
}

resource "kubernetes_cluster_role_binding" "external_dns" {
  metadata {
    name = "external-dns"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.external_dns.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.external_dns.metadata[0].name
    namespace = kubernetes_service_account.external_dns.metadata[0].namespace
  }
}

resource "kubernetes_deployment" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "external-dns"
  }

  spec {
    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "external-dns"
      }
    }

    template {
      metadata {
        labels = {
          app = "external-dns"
        }
      }

      spec {
        container {
          name  = "external-dns"
          image = "k8s.gcr.io/external-dns/external-dns:v${var.external_dns_version}"

          args = [
            "--source=ingress",
            "--source=service",
            "--source=istio-gateway",
            "--source=virtualservice",
            "--domain-filter=${data.google_dns_managed_zone.dns_zone.dns_name}",
            "--provider=google",
            "--google-project=${var.project_id}",
            "--registry=txt",
            "--log-format=json",
            "--policy=upsert-only",
            "--txt-owner-id=external-dns"
          ]
        }

        security_context {
          fs_group    = 65534
          run_as_user = 65534
        }

        service_account_name = google_service_account.external_dns.name
      }
    }
  }
}
