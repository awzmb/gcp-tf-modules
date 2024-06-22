locals {
  gke_cluster_name = "gke-${var.name}"

  internal_subnet_cidr   = "10.0.0.0/24"
  master_ipv4_cidr_block = "172.16.0.16/28"
  proxy_only_ipv4_cidr   = "11.129.0.0/23"
}
