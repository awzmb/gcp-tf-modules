variable "repository_id" {
  description = "The repository name."
  type        = string
}

variable "location" {
  description = "The name of the location this repository is located in."
  type        = string
}

variable "format" {
  description = "The format of packages that are stored in the repository. You can only create alpha formats if you are a member of the alpha user group. Possible values are: [DOCKER,MAVEN,NPM,PYTHON,APT,YUM,KUBEFLOW,GO,GENERIC]"
  type        = string
  default     = "DOCKER"
}
