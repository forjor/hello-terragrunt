include "root" {
  path = find_in_parent_folders()
}

locals {
  # Automatically load hierarchical variables
  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Extract out common variables for reuse
  usershort   = local.account_vars.locals.usershort
  aws_region  = local.region_vars.locals.aws_region
  env         = local.environment_vars.locals.environment
  primary_env = local.environment_vars.locals.primary_environment

  alb_name = "${local.usershort}-${local.env}-${local.aws_region}-alb"

  # Assign values which will differ based on whether we use a domain
  security_group_ingress_rules_with_domain = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_ingress_rules_no_domain = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
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
  config_path = "../../../${local.primary_env}/network/vpc"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id         = "vpc-09e4254823001c6cf"
    vpc_cidr_block = "10.0.0.0/16"
    public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  }
}

dependency "acm" {
  config_path = "../../../_global/network/acm"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    acm_certificate_arn = "arn:aws:acm:us-east-1:374043564547:certificate/b22c0b82-04d9-45f5-bba4-9bd1e0c6f84b"
  }
}

dependency "subdomain" {
  config_path = "../../../../_global/network/subdomain"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    full_subdomain    = "fake.subdomain.com"
    subdomain_zone_id = "ABCD1234"
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
  security_group_ingress_rules = dependency.subdomain.outputs.full_subdomain == "" ? local.security_group_ingress_rules_no_domain : local.security_group_ingress_rules_with_domain
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = dependency.vpc.outputs.vpc_cidr_block
    }
  }
  
  # Note that we are using some unusual values for HTTP just as a workaround for the inconsistent types conditional limitation
  listeners = {
    ex_http_or_https = dependency.subdomain.outputs.full_subdomain == "" ? {
      port            = 80
      protocol        = "HTTP"
      ssl_policy      = null
      certificate_arn = null

      forward = {
        target_group_key = "ex_ecs"
      }
      } : {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
      certificate_arn = dependency.acm.outputs.acm_certificate_arn

      forward = {
        target_group_key = "ex_ecs"
      }
    }

    http-https-redirect = dependency.subdomain.outputs.full_subdomain == "" ? {
      port     = 8080
      protocol = "HTTP"

      redirect = {
        port        = "80"
        protocol    = "HTTP"
        status_code = "HTTP_301"
      }
      } : {
      port     = 80
      protocol = "HTTP"

      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  route53_records = dependency.subdomain.outputs.full_subdomain == "" ? {} : {
    A = {
      name    = "ecs-${local.aws_region}-${local.env}"
      type    = "A"
      zone_id = dependency.subdomain.outputs.subdomain_zone_id
    }
    AAAA = {
      name    = "ecs-${local.aws_region}-${local.env}"
      type    = "AAAA"
      zone_id = dependency.subdomain.outputs.subdomain_zone_id
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
