output "bucket_name" {
  description = "The name of the bucket created."
  value       = google_storage_bucket.static_website.name
}

output "bucket_url" {
  description = "The URL to access the static website."
  value       = "https://storage.googleapis.com/${google_storage_bucket.static_website.name}/${var.index_page}"
}
