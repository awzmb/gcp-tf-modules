
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

resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = var.istio_version

  namespace = "istio-system"

  dependency_update = true
  create_namespace  = true
  wait_for_jobs     = true
  atomic            = true

  set {
    name  = "defaultRevision"
    value = "default"
  }
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = var.istio_version

  namespace = "istio-system"

  dependency_update = true
  create_namespace  = true
  wait_for_jobs     = true

  depends_on = [
    helm_release.istio_base
  ]
}

# create a namespace for the istio gateway with the istio-injection label.
# else the istio gateway will not be injected with the istio sidecar and
# the helm deployment will fail.
resource "kubernetes_namespace" "istio_gateway" {
  metadata {
    labels = {
      istio-injection = "enabled"
    }

    name = "istio-gateway"
  }
}

resource "helm_release" "istio_gateway" {
  name       = "istio-gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = var.istio_version

  namespace = "istio-gateway"

  dependency_update = true
  wait_for_jobs     = true

  values = [
    <<EOF
service:
  type: ClusterIP
  ports:
    - name: status-port
      port: 15021
      protocol: TCP
      targetPort: 15021
    - name: http2
      port: 80
      protocol: TCP
      targetPort: 80
    - name: https
      port: 443
      protocol: TCP
      targetPort: 443
  annotations:
    cloud.google.com/neg: '{"exposed_ports": {"80":{"name": "${var.istio_ingress_gateway_endpoint_group_http}"},"443":{"name": "${var.istio_ingress_gateway_endpoint_group_https}"}}}'
  loadBalancerIP: ""
  loadBalancerSourceRanges: []
  externalTrafficPolicy: ""
  externalIPs: []
labels:
  istio: private-ingressgateway
EOF
  ]

  set {
    name  = "revision"
    value = replace(var.istio_version, ".", "-")
  }

  set {
    name  = "image.repository"
    value = "gcr.io/istio-release/proxyv2"
  }

  set {
    name  = "imagePullPolicy"
    value = "IfNotPresent"
  }

  set {
    name  = "global.controlPlaneSecurityEnabled"
    value = "true"
  }

  depends_on = [
    helm_release.istiod,
    kubernetes_namespace.istio_gateway,
  ]
}
