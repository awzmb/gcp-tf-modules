# deploy istio via submodule to tackle the data object dependency
# problem on the first deployment of the cluster.
#module "external_dns" {
#source = "./submodules/external-dns"

#cluster_name = google_container_cluster.default.name
#region       = var.region
#project_id   = var.project_id

#external_dns_version = "0.14.2"

#dns_zone_name = var.dns_zone_name
#}

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
  role_id = "manage_dns_records_${random_id.random_role_id_suffix.hex}"
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
          image = "k8s.gcr.io/external-dns/external-dns:v${local.external_dns_version}"

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

  depends_on = [
    kubernetes_service_account.external_dns,
    kubernetes_cluster_role_binding.external_dns,
  ]
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = local.external_dns_version

  namespace = "external-dns"

  dependency_update = true
  create_namespace  = true
  wait_for_jobs     = true
  atomic            = true

  values = [
    <<EOF
extraArgs:
  - --source=ingress
  - --source=service
  - --source=istio-gateway
  - --source=virtualservice
  - --domain-filter=${data.google_dns_managed_zone.dns_zone.dns_name}
  - --provider=google
  - --google-project=${var.project_id}
  - --registry=txt
  - --log-format=json
  - --policy=upsert-only
  - --txt-owner-id=external-dns
EOF
  ]
}
