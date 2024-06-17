data "terraform_remote_state" "healthChecks" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/healthChecks/europe-north1/terraform.tfstate"
  }
}

data "terraform_remote_state" "instanceGroupManagers" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/instanceGroupManagers/europe-north1/terraform.tfstate"
  }
}

data "terraform_remote_state" "regionInstanceGroupManagers" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/regionInstanceGroupManagers/europe-north1/terraform.tfstate"
  }
}
