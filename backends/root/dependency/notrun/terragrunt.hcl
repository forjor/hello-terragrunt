include "root" {
  path = "../../terragrunt.hcl"
}

terraform {
  source = "../../../..//modules/passthrough"
}

inputs = {
  input_value = "This module will not be run if run-all is called from the VPC folder."
}
