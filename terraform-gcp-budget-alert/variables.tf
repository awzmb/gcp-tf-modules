variable "credentials_file_path" {
  description = "Path to the GCP credentials file"
  type        = string
}

variable "project_id" {
  description = "The ID of the project in which to create the budget alert resources"
  type        = string
}

variable "billing_account_id" {
  description = "The ID of the billing account to create the budget alert for"
  type        = string
}

variable "budget_name" {
  description = "The name of the budget"
  type        = string
}

variable "budget_amount" {
  description = "The amount for the budget in USD"
  type        = number
}

variable "project_ids" {
  description = "The list of project IDs under the billing account"
  type        = list(string)
}

variable "email" {
  description = "Email address to send budget alerts to"
  type        = string
}

variable "push_endpoint" {
  description = "The endpoint to push the notifications to"
  type        = string
}
