resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = local.istio_version

  #values = [
  #file("istio-values.yaml")
  #]

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

  set {
    name  = "global.proxy.image"
    value = "auto"
  }

  set {
    name  = "global.controlPlaneSecurityEnabled"
    value = "true"
  }

  depends_on = [
    helm_release.istio_base
  ]
}

resource "helm_release" "istio_gateway" {
  name       = "istio-gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = local.istio_version

  depends_on = [
    helm_release.istiod
  ]
}
