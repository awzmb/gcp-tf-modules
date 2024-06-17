data "terraform_remote_state" "networks" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/networks/europe-north1/terraform.tfstate"
  }
}

data "terraform_remote_state" "subnetworks" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/subnetworks/europe-north1/terraform.tfstate"
  }
}
