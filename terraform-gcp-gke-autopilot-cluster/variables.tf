variable "name" {
  description = "Name of the cluster (and additional resources)."
  type        = string
}

variable "project_id" {
  description = "The project ID to host the cluster in."
  type        = string
}

variable "zone" {
  description = "The zone to host the cluster and endpoints in."
  type        = string
}

variable "region" {
  description = "The region to host the cluster in."
  type        = string
}

variable "num_nodes" {
  description = "The number of cluster nodes."
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "The machine type of the cluster nodes."
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size" {
  description = "The disk size of the cluster nodes."
  type        = string
  default     = 60
}

variable "dns_zone_name" {
  description = "Name of the DNS zone the cluster is allowed create records in."
  type        = string
}

variable "release_channel" {
  description = "Set the release channel for this cluster. Valid values are: REGULAR, RAPID and STABLE."
  type        = string
  default     = "REGULAR"

  validation {
    condition     = var.release_channel == "REGULAR" || var.release_channel == "RAPID" || var.release_channel == "STABLE"
    error_message = "The release channel must bei either REGULAR, RAPID or STABLE."
  }
}

variable "enable_istio" {
  description = "Enable deployment of Istio on the cluster."
  type        = bool
  default     = true
}

variable "proxy_mode" {
  description = "Proxy mode to use. HTTP for http2/https load balancing, TCP for tcp passthrough (80/443) load balancing. Valid values are: HTTP, TCP."
  type        = string
}
