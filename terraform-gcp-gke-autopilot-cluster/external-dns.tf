resource "google_service_account" "external_dns" {
  account_id   = "external-dns"
  display_name = "external-dns Service Account"
  project      = var.project_id
}

resource "google_project_iam_binding" "external_dns" {
  project = var.project_id
  role    = "roles/dns.admin"
  members = [google_service_account.external_dns.member]
}

resource "google_service_account_iam_member" "external_dns_workload_identity" {
  service_account_id = google_service_account.external_dns.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-dns/external-dns]"
}

resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = "external-dns"
  }
}

resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = kubernetes_namespace.external_dns.metadata[0].name

    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.external_dns.email
    }
  }

  depends_on = [
    google_container_cluster.default
  ]
}

resource "kubernetes_cluster_role" "external_dns" {
  metadata {
    name = "external-dns"
  }

  rule {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods", "nodes", "namespaces"]
    verbs      = ["list", "get", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["list", "get", "watch"]
  }

  # watch gateway apis
  rule {
    api_groups = ["gateway.networking.k8s.io"]
    resources  = ["gateways", "httproutes", "tlsroutes", "tcproutes", "udproutes"]
    verbs      = ["list", "get", "watch"]
  }

  # watch istio resources
  rule {
    api_groups = ["networking.istio.io"]
    resources  = ["virtualservices", "gateways"]
    verbs      = ["list", "get", "watch"]
  }

  depends_on = [
    google_container_cluster.default
  ]
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
  #checkov:skip=CKV_K8S_43:no digest for this image
  metadata {
    name      = "external-dns"
    namespace = kubernetes_namespace.external_dns.metadata[0].name
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

        annotations = {
          "sidecar.istio.io/inject"        = "false"
          "iam.gke.io/gcp-service-account" = google_service_account.external_dns.email
        }
      }

      spec {
        container {
          name              = "external-dns"
          image             = "registry.k8s.io/external-dns/external-dns:v${local.external_dns_version}"
          image_pull_policy = "Always"

          args = [
            "--source=ingress",
            "--source=service",
            "--source=istio-gateway",
            "--source=istio-virtualservice",
            "--domain-filter=${data.google_dns_managed_zone.dns_zone.dns_name}",
            "--provider=google",
            "--google-project=${var.project_id}",
            "--registry=txt",
            "--log-format=json",
            "--policy=upsert-only",
            "--txt-owner-id=${var.project_id}",
            "--log-level=debug",
          ]

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 7979
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            failure_threshold     = 3
            success_threshold     = 1
            timeout_seconds       = 5
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 7979
            }
            initial_delay_seconds = 5
            period_seconds        = 10
            failure_threshold     = 3
            success_threshold     = 1
            timeout_seconds       = 5
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "100Mi"
            }
            limits = {
              cpu    = "800m"
              memory = "1024Mi"
            }
          }

          security_context {
            privileged                 = false
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            run_as_user                = 65532
            run_as_group               = 65532

            capabilities {
              drop = ["ALL"]
            }
          }
        }

        service_account_name = kubernetes_service_account.external_dns.metadata[0].name
      }
    }
  }

  depends_on = [
    google_container_cluster.default,
    google_service_account_iam_member.external_dns_workload_identity,
    kubernetes_namespace.external_dns,
    kubernetes_service_account.external_dns,
    kubernetes_cluster_role_binding.external_dns,
  ]
}
