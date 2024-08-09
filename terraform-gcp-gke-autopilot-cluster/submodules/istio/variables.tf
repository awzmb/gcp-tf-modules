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

variable "http_backend_service_name" {
  description = "The name of the backend service for the Istio ingress gateway (http/port 80)."
  type        = string
}

variable "https_backend_service_name" {
  description = "The name of the backend service for the Istio ingress gateway (https/port 443)."
  type        = string
}
