terraform {
  required_version = ">=1.3"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.0, < 3"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30.0, < 3"
    }
  }
}

data "google_client_config" "default" {}

data "google_container_cluster" "default" {
  name     = var.cluster_name
  location = var.region
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
  account_id = "external-dns"
}

resource "google_project_iam_member" "workload_identity_user_binding" {
  project = "your-gcp-project-id" # Replace with your GCP project ID
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

  # istio
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

  subjects {
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
          image = "k8s.gcr.io/external-dns/external-dns:v0.8.0"

          args = [
            "--source=ingress",
            "--source=service",
            "--source=istio-gateway",
            "--source=virtualservice",
            "--domain-filter=${var.domain}",
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

        service_account_name = "external-dns"
      }
    }
  }
}
