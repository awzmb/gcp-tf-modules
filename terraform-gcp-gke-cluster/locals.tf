locals {
  gke_cluster_name = "gke-${var.name}"

  istio_version = "1.22.1"

  internal_subnet_cidr   = "10.0.0.0/24"
  master_ipv4_cidr_block = "172.16.0.16/28"
  proxy_only_ipv4_cidr   = "11.129.0.0/23"

  cluster_ipv4_cidr_block  = "5.0.0.0/16"
  services_ipv4_cidr_block = "5.1.0.0/16"

}
