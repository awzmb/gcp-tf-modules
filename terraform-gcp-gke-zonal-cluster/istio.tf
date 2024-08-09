# deploy istio via submodule to tackle the data object dependency
# problem on the first deployment of the cluster.
module "istio" {
  source = "./submodules/istio"

  cluster_name = google_container_cluster.default.name
  region       = var.region

  istio_version = local.istio_version

  istio_ingress_gateway_endpoint_group_http  = local.istio_ingress_gateway_endpoint_group_http
  istio_ingress_gateway_endpoint_group_https = local.istio_ingress_gateway_endpoint_group_https
}
