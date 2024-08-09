variable "zone_name" {
  description = "The name of the DNS zone."
  type        = string
}

variable "dns_zone" {
  description = "The DNS name for the managed zone (g.e. private.example.com)."
  type        = string
}

variable "labels" {
  description = "A map of labels to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "dns_records" {
  description = "A map of DNS records to create in the managed zone."
  type = map(object({
    name    = string
    type    = string
    ttl     = number
    rrdatas = list(string)
  }))
  default = {}
}
