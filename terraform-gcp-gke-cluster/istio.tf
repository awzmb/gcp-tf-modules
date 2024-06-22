resource "helm_release" "istio" {
  name       = "istio"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istio"
  version    = "latest"

  #values = [
  #file("istio-values.yaml")
  #]

  set {
    name  = "global.proxy.image"
    value = "auto"
  }

  set {
    name  = "global.controlPlaneSecurityEnabled"
    value = "true"
  }
}

