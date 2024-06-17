data "terraform_remote_state" "targetHttpProxies" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/targetHttpProxies/europe-north1/terraform.tfstate"
  }
}

data "terraform_remote_state" "targetHttpsProxies" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/targetHttpsProxies/europe-north1/terraform.tfstate"
  }
}

data "terraform_remote_state" "targetSslProxies" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/targetSslProxies/europe-north1/terraform.tfstate"
  }
}
