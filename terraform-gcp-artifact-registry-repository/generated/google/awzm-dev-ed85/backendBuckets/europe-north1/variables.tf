data "terraform_remote_state" "gcs" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/gcs/europe-north1/terraform.tfstate"
  }
}
