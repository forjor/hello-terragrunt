include "root" {
  path = find_in_parent_folders()
}

locals {
  # Automatically load hierarchical variables
  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract out common variables for reuse
  account_name = local.account_vars.locals.account_name
  aws_region   = local.region_vars.locals.aws_region
  env          = local.environment_vars.locals.environment

  acm_name = "${local.account_name}-${local.aws_region}-acm"
}

terraform {
  source = "tfr:///terraform-aws-modules/acm/aws?version=5.0.0"
}

dependency "subdomain" {
  config_path = "../../../../_global/network/subdomain"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    full_subdomain = "fake.subdomain.com"
    subdomain_zone_id = "ABCD1234"
  }
}

inputs = {
  create_certificate = dependency.subdomain.outputs.full_subdomain != "" ? true : false

  domain_name          = "*.${dependency.subdomain.outputs.full_subdomain}"
  validate_certificate = true
  validation_method    = "DNS"
  zone_id              = dependency.subdomain.outputs.subdomain_zone_id

  tags = {
    Name        = local.acm_name
    Environment = local.env
    Terraform   = "true"
  }
}
