data "terraform_remote_state" "urlMaps" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/urlMaps/europe-north1/terraform.tfstate"
  }
}
