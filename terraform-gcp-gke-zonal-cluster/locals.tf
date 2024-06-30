locals {
  gke_cluster_name = "gke-${var.name}"

  istio_version = "1.22.1"

  internal_subnet_cidr   = "10.0.0.0/24"
  master_ipv4_cidr_block = "172.16.0.16/28"
  proxy_only_ipv4_cidr   = "11.129.0.0/23"

  cluster_ipv4_cidr_block  = "5.0.0.0/16"
  services_ipv4_cidr_block = "5.1.0.0/16"

  istio_ingress_gateway_endpoint_group = "private-istio-ingress-gateway"

  istio_ingress_gateway_endpoint_group_http  = "${local.istio_ingress_gateway_endpoint_group}-http"
  istio_ingress_gateway_endpoint_group_https = "${local.istio_ingress_gateway_endpoint_group}-https"

  istio_ingress_gateway_endpoint_group_http_backend_service  = "${local.istio_ingress_gateway_endpoint_group_http}-backend-service"
  istio_ingress_gateway_endpoint_group_https_backend_service = "${local.istio_ingress_gateway_endpoint_group_https}-backend-service"
}
