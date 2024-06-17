data "terraform_remote_state" "networks" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/networks/europe-north1/terraform.tfstate"
  }
}

data "terraform_remote_state" "regionBackendServices" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/regionBackendServices/europe-north1/terraform.tfstate"
  }
}
