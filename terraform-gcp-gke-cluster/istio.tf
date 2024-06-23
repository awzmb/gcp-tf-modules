resource "helm_release" "istio_base" {
  count = var.enable_istio ? 1 : 0

  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = local.istio_version

  namespace = "istio-system"

  dependency_update = true
  create_namespace  = true
  wait_for_jobs     = true
  atomic            = true

  #values = [
  #file("istio-values.yaml")
  #]

  set {
    name  = "defaultRevision"
    value = "default"
  }
}

resource "helm_release" "istiod" {
  count = var.enable_istio ? 1 : 0

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

resource "helm_release" "istio_gateway" {
  count = var.enable_istio ? 1 : 0

  name       = "istio-gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = local.istio_version

  namespace = "istio-gateway"

  dependency_update = true
  create_namespace  = true
  wait_for_jobs     = true

  values = [
    yamlencode(local.istio_ingress_gateway_values)
  ]

  set {
    name  = "revision"
    value = replace(local.istio_version, ".", "-")
  }

  set {
    name  = "global.controlPlaneSecurityEnabled"
    value = "true"
  }

  depends_on = [
    helm_release.istiod
  ]
}
