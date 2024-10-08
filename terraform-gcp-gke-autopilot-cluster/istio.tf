resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = local.istio_version

  namespace = "istio-system"

  dependency_update = true
  create_namespace  = true
  wait_for_jobs     = true
  atomic            = true

  set {
    name  = "defaultRevision"
    value = "default"
  }

  depends_on = [
    google_container_cluster.default
  ]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = local.istio_version

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
  version    = local.istio_version

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
    cloud.google.com/neg: '{"exposed_ports": {"80":{},"443":{}}}'
    controller.autoneg.dev/neg: '{"backend_services":{"80":[{"name":"${local.http_backend_service_name}","max_rate_per_endpoint":100}]},"443":[{"name":"${local.https_backend_service_name}","max_rate_per_endpoint":100}]}}'
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
    value = replace(local.istio_version, ".", "-")
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
