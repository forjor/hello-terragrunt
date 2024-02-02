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

  alb_name = "${local.account_name}-${local.aws_region}-alb"
}

terraform {
  source = "tfr:///terraform-aws-modules/alb/aws?version=9.5.0"
}

dependency "region_data" {
  config_path = "../../../_global/region-data"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  }
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id         = "vpc-09e4254823001c6cf"
    vpc_cidr_block = "10.0.0.0/16"
    public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  }
}

# Indicate the input values to use for the variables of the module.
inputs = {
  name = local.alb_name

  load_balancer_type = "application"

  vpc_id  = dependency.vpc.outputs.vpc_id
  subnets = dependency.vpc.outputs.public_subnets

  # For example only
  enable_deletion_protection = false

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = dependency.vpc.outputs.vpc_cidr_block
    }
  }

  listeners = {
    ex_http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ex_ecs"
      }
    }
  }

  target_groups = {
    ex_ecs = {
      backend_protocol                  = "HTTP"
      backend_port                      = 3000
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # There's nothing to attach here in this definition. Instead,
      # ECS will attach the IPs of the tasks to this target group
      create_attachment = false
    }
  }

  tags = {
    Name        = local.alb_name
    Environment = local.env
    Terraform   = "true"
  }
}
