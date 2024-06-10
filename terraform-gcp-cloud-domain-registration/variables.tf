variable "domain_name" {
  description = "Name of the domain to be registered."
  type        = string

  validation {
    condition     = can(regex("[a-zA-Z0-9-]{1,63}\\.([a-zA-Z]{2,})", var.domain_name))
    error_message = "The 'domain_name' variable must be a valid domain name."
  }
}

variable "pricing_currency_code" {
  description = "The three-letter currency code defined in ISO 4217 (g.e. EUR, USD, YEN)."
  type        = string
}

variable "pricing_yearly_price" {
  description = "The yearly price to register or renew the domain."
  type        = number
}

variable "labels" {
  description = "A set of key/value label pairs to assign to the resource."
  type        = map(string)
  default     = {}
}

variable "region_code" {
  description = "Registrant contact region code."
  type        = string

  validation {
    condition     = length(var.region_code) == 2
    error_message = "The variable must be a 2-letter country code."
  }
}

variable "organization" {
  description = "Registrant contact organization."
  type        = string
}

variable "postal_code" {
  description = "Registrant contact postal code."
  type        = string
}

variable "city" {
  description = "Registrant contact city name."
  type        = string
}

variable "address" {
  description = "Registrant contact address lines."
  type        = string
}

variable "administrative_area" {
  description = "Registrant contact administrative area. Two-letter code g.e. CA, BE."
  type        = string

  validation {
    condition     = length(var.administrative_area) == 2
    error_message = "The administrative_area variable must be a 2-letter country code."
  }
}

variable "email_address" {
  description = "Registrant contact email."
  type        = string

  validation {
    condition     = can(regex("^\\S+@\\S+$", var.email_address))
    error_message = "The email_address variable must be a valid email address."
  }
}

variable "phone_number" {
  description = "Registrant contact phone number."
  type        = string

  validation {
    condition     = can(regex("^\\+?\\d+$", var.phone_number))
    error_message = "The phone_number variable must be a valid phone number."
  }
}
