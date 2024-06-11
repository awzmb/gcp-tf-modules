output "domain_name" {
  description = "The domain name of the registration."
  value       = google_clouddomains_registration.default.domain_name
}

output "create_time" {
  description = "The creation time of the registration."
  value       = google_clouddomains_registration.default.create_time
}

output "expire_time" {
  description = "The expiration time of the registration."
  value       = google_clouddomains_registration.default.expire_time
}

output "state" {
  description = "The state of the registration."
  value       = google_clouddomains_registration.default.state
}

