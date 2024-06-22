variable "name" {
  description = "Name of the cluster (and additional resources)"
  type        = string
}

variable "project_id" {
  description = "The project ID to host the cluster in"
  type        = string
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
}

variable "network_name" {
  description = "The name of the network"
  type        = string
}

variable "num_nodes" {
  description = "The number of cluster nodes"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "The machine type of the cluster nodes"
  type        = string
}

variable "disk_size" {
  description = "The disk size of the cluster nodes"
  type        = string
  default     = 60
}

variable "domain" {
  description = "Domain of the cluster"
  type        = string
}
