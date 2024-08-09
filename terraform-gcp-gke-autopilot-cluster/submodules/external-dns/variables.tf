variable "cluster_name" {
  description = "Name of the cluster (and additional resources)."
  type        = string
}

variable "project_id" {
  description = "The project ID the cluster is hosted in."
  type        = string
}

variable "region" {
  description = "The region the cluster is hosted in."
  type        = string
}

variable "external_dns_version" {
  description = "The version of external-dns to deploy. NOTE: this uses the https://kubernetes-sigs.github.io/external-dns/ chart, not the Bitnami chart."
  type        = string
}

variable "dns_zone_name" {
  description = "DNS zone name to manage (should be identical to the cluster DNS zone)."
  type        = string
}
