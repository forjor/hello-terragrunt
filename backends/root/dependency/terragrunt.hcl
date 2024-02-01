include "root" {
  path = find_in_parent_folders()
  expose = "true"
}

terraform {
  source = "../../..//modules/passthrough"
}

inputs = {
  input_value = "hello-tg-vpc-${include.root.locals.username}"
}
