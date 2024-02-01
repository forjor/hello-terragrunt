include "root" {
  path = "../../terragrunt.hcl"
}

terraform {
  source = "../../../..//modules/passthrough"
}

inputs = {
  input_value = "Just a value."
}
