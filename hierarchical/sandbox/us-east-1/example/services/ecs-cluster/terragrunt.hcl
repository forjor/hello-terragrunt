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

  ecs_name = "${local.account_name}-${local.aws_region}-ecs"
}

terraform {
  source = "tfr:///terraform-aws-modules/ecs/aws//modules/cluster?version=5.8.0"
}

# Indicate the input values to use for the variables of the module.
inputs = {
  cluster_name = local.ecs_name

  # Capacity provider
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  tags = {
    Name        = local.ecs_name
    Environment = local.env
    Terraform   = "true"
  }
}
