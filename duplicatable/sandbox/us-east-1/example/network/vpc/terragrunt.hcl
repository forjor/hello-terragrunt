include "root" {
  path = find_in_parent_folders()
}

locals {
  # Automatically load hierarchical variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract out common variables for reuse
  account_name = local.account_vars.locals.account_name
  aws_region   = local.region_vars.locals.aws_region
  env          = local.environment_vars.locals.environment
  primary_env  = local.environment_vars.locals.primary_environment

  vpc_name = "${local.account_name}-${local.aws_region}-vpc"
}

terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.5.1"
}

dependency "region_data" {
  config_path = "../../../_global/region-data"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  }
}

# Indicate the input values to use for the variables of the module.
inputs = {
  name = local.vpc_name

  # Only create VPCs in the primary environment
  create = local.env == local.primary_env

  cidr            = "10.0.0.0/16"
  azs             = dependency.region_data.outputs.azs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true

  tags = {
    Name        = local.vpc_name
    Environment = local.env
    Terraform   = "true"
  }
}
