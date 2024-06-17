data "terraform_remote_state" "instanceTemplates" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/awzm-dev-ed85/instanceTemplates/europe-north1/terraform.tfstate"
  }
}
