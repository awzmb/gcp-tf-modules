variable "display_name" {
  description = "Display name of the project."
  type        = string
}

variable "project_id" {
  description = "Identifier of the project."
  type        = string
}

variable "billing_account_id" {
  description = "The alphanumeric ID of the billing account this project belongs to. The user or service account performing this operation with Terraform must have at minimum Billing Account User privileges (roles/billing.user) on the billing account. See Google Cloud Billing API Access Control for more details."
  type        = string
}
