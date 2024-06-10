variable "domain_name" {
  description = "Name of the domain to be registered."
  type        = string
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
}

variable "email_address" {
  description = "Registrant contact email."
  type        = string
}

variable "phone_number" {
  description = "Registrant contact phone number."
  type        = string
}
