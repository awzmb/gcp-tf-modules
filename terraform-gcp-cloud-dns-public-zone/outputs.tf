output "zone_id" {
  description = "The ID of the DNS zone."
  value       = google_dns_managed_zone.zone.id
}

output "zone_name" {
  description = "The name of the DNS zone."
  value       = google_dns_managed_zone.zone.name
}

output "name_servers" {
  description = "Delegate your managed_zone to these virtual name servers; defined by the server."
  value       = google_dns_managed_zone.zone.name_servers
}
