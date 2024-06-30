variable "name" {
  description = "The name for this CaPool."
  type        = string
}

variable "region" {
  description = "The region to host the CaPool in."
  type        = string
}

variable "domain" {
  description = "Domain able to utilize the CA pool."
  type        = string
}

variable "tier" {
  description = "The Tier of this CaPool. Possible values are: ENTERPRISE, DEVOPS."
  type        = string
}

