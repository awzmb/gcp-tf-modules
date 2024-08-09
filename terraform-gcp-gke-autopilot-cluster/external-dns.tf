# deploy istio via submodule to tackle the data object dependency
# problem on the first deployment of the cluster.
module "external_dns" {
  source = "./submodules/external-dns"

  cluster_name = google_container_cluster.default.name
  region       = var.region
  project_id   = var.project_id

  external_dns_version = "0.14.2"

  dns_zone_name = var.dns_zone_name
}
