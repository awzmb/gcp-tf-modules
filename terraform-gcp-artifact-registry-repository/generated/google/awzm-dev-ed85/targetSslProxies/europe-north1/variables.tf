data "terraform_remote_state" "backendServices" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/backendServices/europe-north1/terraform.tfstate"
  }
}
