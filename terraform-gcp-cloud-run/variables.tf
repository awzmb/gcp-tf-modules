variable "project_id" {
  description = "The project ID to deploy to."
  type        = string
}

variable "name" {
  description = "The name of the Cloud Run service to create."
  type        = string
}

variable "location" {
  description = "Cloud Run service deployment location."
  type        = string
}

variable "image" {
  description = "GCR hosted image URL to deploy."
  type        = string
}

variable "generate_revision_name" {
  type        = bool
  description = "Option to enable revision name generation."
  default     = true
}

variable "service_labels" {
  type        = map(string)
  description = "A set of key/value label pairs to assign to the service."
  default     = {}
}

variable "invokers" {
  type        = list(string)
  description = "Users/SAs to be given invoker access to the service."
  default     = []
}
