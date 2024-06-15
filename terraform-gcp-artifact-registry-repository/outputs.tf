output "artifact_id" {
  description = "An identifier for the docker repo"
  value       = module.artifact_registry.artifact_id
}
output "project_id" {
  description = "Project ID"
  value       = data.google_project.project.number
}

output "repo_location" {
  description = "Location of the Artifact Registry"
  value       = var.location
}
