output "id" {
  description = "An identifier for the resource with format projects/{{project}}/locations/{{location}}/repositories/{{repository_id}}."
  value       = google_artifact_registry_repository.repository.id
}

output "name" {
  description = "The name of the repository, for example: repo1."
  value       = google_artifact_registry_repository.repository.id
}

output "project_id" {
  description = "Project ID"
  value       = data.google_project.project.number
}

output "repo_location" {
  description = "Location of the Artifact Registry"
  value       = var.location
}
