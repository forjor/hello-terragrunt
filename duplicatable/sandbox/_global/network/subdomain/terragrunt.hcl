include "root" {
  path = find_in_parent_folders()
}

locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  usershort = local.account_vars.locals.usershort
}

terraform {
  before_hook "before_hook" {
    commands     = ["plan", "apply", "validate"]
    execute      = ["./prompt_for_hosted_zone.sh"]
  }
}

inputs = {
    subdomain_prefix = "dupe-${local.usershort}"
}
