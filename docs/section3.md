# Section 3 - Backend generation and dependency resolution.

In this section we create a hierarchy of directories to manage common configuration elements.

## Scoping Configuration

This section will be based around an [ECS fargate example](https://github.com/terraform-aws-modules/terraform-aws-ecs/tree/v5.8.0/examples/fargate) which has been converted into a terragrunt style.

The main items this section looks at are:
- Using nested directories to automatically drive configuration for the scope of concern
- Using mock outputs to execute a full tree of configurations without applying intermediary nodes

To exercise this increment we'll start by logging in to our AWS sandbox and entering the `hierarchical/sandbox/us-east-1/example/network/alb` directory. The AWS Loab Balancer (alb) is a terragrunt config which consumes remote state from multiple dependencies to drive its inputs.

Within the `hierarchical/sandbox/us-east-1/example/network/alb` directory we can again start by running `terragrunt run-all plan`. Once again we will respond `y` to any prompt to proceed with creation of state.

This time we see successful plans return for each config - this is because we used `mock_outputs` entries in the `terragrunt.hcl` files to allow mock data injection for `validate` and `plan` commands.

Next we can switch to the `hierarchical/sandbox/us-east-1/example/services/ecs-service` directory and try the same operation. This time, however, we will see a failure. This is because some modules will attempt to leverage the mock data during a plan operation to get feedback from a live environment. When mock data like a subnet ID does not match something which exists in our AWS environment the underlying terraform will fail during planning. Although these situations mean some modules are never suitable to `run-all plan` in the absence of their dependencies, the `mock_outputs` may still be useful for `run-all validate` commands to verify the terraform is properly formatted and runnable. We can run `terragrunt run-all validate` now from `hierarchical/sandbox/us-east-1/example/services/ecs-service` and see the terraform is valid. Next we can run `terragrunt run-all apply` to stand up the full stack of configs.

After running our apply we can look in the AWS console and see our resources. They all have our name reflected in their names and in their tags - this can be helpful for sandbox or experimental setups. We can see how this data propogates from a single source of truth in `hierarchical/sandbox/account.hcl` and is pulled in through various `terragrunt.hcl` files with the lines:
```account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))```
and
```account_name = local.account_vars.locals.account_name```

We can see that the region and environment variables are passed into the tree of configs in a similar way. These techniques are equally useful for organizing identifiers and other pieces of common data in live pre-prod and production environments.

To tear down our stacks we can switch to the `hierarchical/sandbox` directory and run `terragrun run-all destroy`.

The backing state files and lock tables may be cleaned up manually.
