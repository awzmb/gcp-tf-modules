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

resource "helm_release" "istio_gateways" {
  for_each = toset(["${var.region}-a", "${var.region}-b", "${var.region}-c"])

  name       = "istio-gateway-${each.key}"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = local.istio_version

  namespace = "istio-gateway"

  dependency_update = true
  create_namespace  = true
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
    cloud.google.com/neg: '{"exposed_ports": {"80":{"name": "${local.istio_ingress_gateway_endpoint_group_http}-${each.key}"}}}'
    cloud.google.com/neg-affinity: '{"zones": ["${each.key}"]}'
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
    helm_release.istiod
  ]
}
