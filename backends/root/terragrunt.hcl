# root/terragrunt.hcl
locals {
  username = get_env("HOST_USER", "unknown")
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "hello-tg-terraform-state-${local.username}"

    key = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "hello-tg-lock-table-${local.username}"
  }
}
