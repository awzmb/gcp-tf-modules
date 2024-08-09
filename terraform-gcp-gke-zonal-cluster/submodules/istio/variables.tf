variable "cluster_name" {
  description = "Name of the cluster (and additional resources)."
  type        = string
}

variable "region" {
  description = "The region the cluster is hosted in."
  type        = string
}

variable "istio_version" {
  description = "The version of Istio to deploy."
  type        = string
}

variable "istio_ingress_gateway_endpoint_group_http" {
  description = "The name of the endpoint group for the Istio ingress gateway (http)."
  type        = string
}

variable "istio_ingress_gateway_endpoint_group_https" {
  description = "The name of the endpoint group for the Istio ingress gateway (https)."
  type        = string
}

