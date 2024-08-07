output "name" {
  value       = google_cloud_run_service.service.name
  description = "Name of the created service"
}

output "revision" {
  value       = google_cloud_run_service.service.status[0].latest_ready_revision_name
  description = "Deployed revision for the service"
}

output "service_url" {
  value       = google_cloud_run_service.service.status[0].url
  description = "The URL on which the deployed service is available"
}

output "project_id" {
  value       = google_cloud_run_service.service.project
  description = "Google Cloud project in which the service was created"
}

output "location" {
  value       = google_cloud_run_service.service.location
  description = "Location in which the Cloud Run service was created"
}

output "service_id" {
  value       = google_cloud_run_service.service.id
  description = "Unique Identifier for the created service"
}

output "service_status" {
  value       = google_cloud_run_service.service.status[0].conditions[0].type
  description = "Status of the created service"
}
