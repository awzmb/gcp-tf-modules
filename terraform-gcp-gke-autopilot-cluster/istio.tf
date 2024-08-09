# deploy istio via submodule to tackle the data object dependency
# problem on the first deployment of the cluster.
module "istio" {
  source = "./submodules/istio"

  cluster_name = google_container_cluster.default.name
  region       = var.region

  istio_version = local.istio_version

  http_backend_service_name  = local.istio_ingress_gateway_endpoint_group_http_backend_service
  https_backend_service_name = local.istio_ingress_gateway_endpoint_group_https_backend_service
}
