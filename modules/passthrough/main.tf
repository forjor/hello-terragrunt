terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.2"
    }
  }
}

resource "null_resource" "just_for_fun" {}
