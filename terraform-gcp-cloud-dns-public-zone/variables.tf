variable "zone_name" {
  description = "The name of the DNS zone."
  type        = string
}

variable "dns_zone" {
  description = "The DNS name for the managed zone (g.e. private.example.com)."
  type        = string
}

variable "tld_registration_name" {
  description = "Setting this glues the dns zone to your top-level domain registration."
  type        = string
  default     = ""
}

variable "labels" {
  description = "A map of labels to assign to the resource."
  type        = map(string)
  default     = {}
}
