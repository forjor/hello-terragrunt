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

  ecs_name       = "${local.account_name}-${local.aws_region}-ecs"
  container_name = "ecsdemo-frontend"
  container_port = 3000
}

terraform {
  source = "tfr:///terraform-aws-modules/ecs/aws//modules/service?version=5.8.0"
}

dependency "region_data" {
  config_path = "../../../_global/region-data"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    fluent_ssm_param = ["fake:image"]
  }
}

dependency "vpc" {
  config_path = "../../network/vpc"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    private_subnets = ["fake", "fake2"]
  }
}

dependency "alb" {
  config_path = "../../network/alb"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    target_groups = {
      ex_ecs = {
        arn = "arn:aws:elasticloadbalancing:eu-west-1:374043564547:targetgroup/tf-2024020219321699960000000a/d066fd8f58c850a2"
      }
    }
    security_group_id = "sg-02728ddb4d193a590"
  }
}

dependency "cluster" {
  config_path = "../ecs-cluster"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    arn = "arn:aws:ecs:eu-west-1:374043564547:cluster/ex-fargate"
  }
}

# Indicate the input values to use for the variables of the module.
inputs = {
  name        = local.ecs_name
  cluster_arn = dependency.cluster.outputs.arn

  cpu    = 1024
  memory = 4096

  # Enables ECS Exec
  enable_execute_command = true

  # Container definition(s)
  container_definitions = {

    fluent-bit = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = dependency.region_data.outputs.fluent_ssm_param
      firelens_configuration = {
        type = "fluentbit"
      }
      memory_reservation = 50
      user               = "0"
    }

    (local.container_name) = {
      cpu       = 512
      memory    = 1024
      essential = true
      image     = "public.ecr.aws/aws-containers/ecsdemo-frontend:776fd50"
      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]

      # Example image used requires access to write to root filesystem
      readonly_root_filesystem = false

      dependencies = [{
        containerName = "fluent-bit"
        condition     = "START"
      }]

      enable_cloudwatch_logging = false
      log_configuration = {
        logDriver = "awsfirelens"
        options = {
          Name                    = "firehose"
          region                  = local.aws_region
          delivery_stream         = "my-stream"
          log-driver-buffer-limit = "2097152"
        }
      }

      linux_parameters = {
        capabilities = {
          drop = [
            "NET_RAW"
          ]
        }
      }

      memory_reservation = 100
    }
  }

  load_balancer = {
    service = {
      target_group_arn = dependency.alb.outputs.target_groups["ex_ecs"].arn
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  subnet_ids = dependency.vpc.outputs.private_subnets
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = local.container_port
      to_port                  = local.container_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = dependency.alb.outputs.security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  service_tags = {
    "ServiceTag" = "Tag on service level"
  }

  tags = {
    Name        = local.ecs_name
    Environment = local.env
    Terraform   = "true"
  }
}
