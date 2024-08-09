variable "project_id" {
  description = "The ID of the GCP project where the bucket will be created."
  type        = string
}

variable "region" {
  description = "The region to deploy the bucket."
  type        = string
}

variable "bucket_name" {
  description = "The name of the GCS bucket."
  type        = string
}

variable "storage_class" {
  description = "The Storage Class of the bucket."
  type        = string
  default     = "STANDARD"
}

variable "index_page" {
  description = "The index page for the website."
  type        = string
  default     = "index.html"
}

variable "error_page" {
  description = "The error page for the website."
  type        = string
  default     = "404.html"
}

variable "force_destroy" {
  description = "When deleting this bucket, delete all objects even if they are not versioned."
  type        = bool
  default     = false
}
