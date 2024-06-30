output "zone_id" {
  description = "The ID of the DNS zone."
  value       = google_dns_managed_zone.zone.id
}

output "zone_name" {
  description = "The name of the DNS zone."
  value       = google_dns_managed_zone.zone.name
}
