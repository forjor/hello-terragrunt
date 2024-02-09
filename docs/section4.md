# Section 4 - External command invocation and duplication workflows.

In this section we use external command invocation to make a workflow interactive and then demonstrate how a full environment can be easily duplicated.

## Interaction through hooks

This sub-section will use [before hooks](https://terragrunt.gruntwork.io/docs/features/hooks/) to enter an interactive dialog with the user. The dialog is driven by an external shell script and uses the AWS CLI to query for available hosted zones and offers the user the chance to select one which will then be used to drive the `terraform.tfvars`. The user may also decline to select one and the example will then be constructed without certificates or named DNS entries.

To exercise this workflow enter the `duplicatable/sandbox` directory and run `terragrunt run-all apply`. After allowing the apply to continue the prompt sequence will begin where the domain may be selected. If a domain is selected a unique subdomain which reflects the current username will be created to prevent collisions off of the chosen base.

For the first pass, exercise the example _without_ a domain selected. (Press `N` then enter)
This case will result in no subdomain, certificate, or ALB A records being created.

It's worth noting that after the full stack has been applied we are in a situation where leaf nodes have created attachments to the trunk nodes. This is an important consideration with terragrunt as it means that if we wanted to switch the stack to run with a domain we would first need to `run-all destroy` before we did another `run-all apply` so that terragrunt could unwind the stack in the correct order automatically. If the domain is added and `run-all apply` is run before running a `run-all destroy` then the deletions of the resources in the trunk nodes would time out and fail because they have attachments.

Feel free to exercise that sequence, if desired:
- Run `terragrun run-all destroy`
- Either delete the `terraform.tfvars` in the `duplicatable/sandbox/_global/network/subdomain` folder and enter `Y` or a valid domain when prompted again, or simple modify `root_domain_name` to be a valid domain
- Run `terragrunt run-all apply`

A few things worth noticing in this workflow are:
- Configs like the `ecs-cluster` and `region-data` have now used the `dependencies` block to ensure they are run after the `subdomain` config to prevent overlapping text in the terminal
- Configs use the presence of the `full_subdomain` output from the `subdomain` config to drive create flags and A-record creation behaviour

## Low-touch duplication of environments

This sub-section looks at how terragrunt configs and common variable files may be arranged to allow for easy duplication of environments and/or regions. We will assume a starting state of either:
- No content has been stood up yet
- The full stack has been stood up _with_ a base domain selected

To start this section we will look at `duplicatable/sandbox/us-east-1/example/env.hcl`. Notice that the file uses the path to the terragrunt config to resolve the name of the `environment` and it also statically defines a `primary_environment`. Environments which are not primary will share the primary environment's VPC.

We can now enter the `duplicatable/sandbox/` directory and execute the `terragrunt run-all apply` command, selecting a valid domain if necessary. This will yield a reachable ECS instance at the address `https://ecs-us-east-1-example.dupe-<usershortname>.<base_domain>/`.

Next we can remove the terragrunt cache to prevent ourselves from copying it: 
``` rm -rf `find . -name '.terragrunt-cache'` ```

Then copy the example environment:
``` cp -r us-east-1/example us-east-1/example2 ```

Then run `terragrunt run-all apply` again. This will yield another ALB, ECS Cluster, and ECS Service in the new environment, reachable at the address `https://ecs-us-east-1-example2.dupe-<usershortname>.<base_domain>/`. The VPC will not be created since it is not the primary environment.

To take it one step further we can remove the caches again and recursively copy the `us-east-1` region to create a `us-east-2` directory tree which also has `example` and `example2` environments within.
(Try to guess the addresses for these services!)

Navigate to `duplicatable/sandbox/` and `terragrunt run-all destroy` to clean up.
