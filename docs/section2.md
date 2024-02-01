# Section 2 - Backend generation and dependency resolution.

In this section we use `run-all` commands to look at terragrunt behaviour for dependency resolution and backend generation.

## Efficient Modularity

A small number of techniques are introduced here which take advantage of terragrunt to:
- Create systematic error-free remote [backends](https://terragrunt.gruntwork.io/docs/reference/built-in-functions/#get_env)
- Re-use local values defined in the root terragrunt file with [exposed includes](https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#include)
- Concisely reference remote state through [dependency](https://terragrunt.gruntwork.io/docs/reference/config-blocks-and-attributes/#dependency) blocks
- Leverage [environment variables](https://terragrunt.gruntwork.io/docs/reference/built-in-functions/#get_env) to prevent collisions in the developer experience

To exercise this increment we can log in to our AWS sandbox and enter the `backends/root/vpc` directory.

The first thing we will look at now is the `run-all plan` subcommand. The `run-all X` subcommands are commands which orchestrate multiple `X` commands (such as `plan`, `apply`, and `destroy`) through set of targets by graphing the dependencies and traversing the resultant tree. These executions target the current folder and _all nested folders_ as well as all _dependencies resolved through dependency blocks_.

Within the `backends/root/vpc` directory we now run `terragrunt run-all plan`. The first thing we will see is terragrunt prompt us to make sure we want to act on the external dependency, aptly named `dependency`. We answer `y`.

We may also see messages throughout this process along the lines of `Remote state S3 bucket <blah> does not exist or you don't have permissions to access it. Would you like Terragrunt to create it?` throughout this process if we have not performed it before. Enter `y` to allow terragrunt to automatically create your backends. Note that terragrunt has read the HOST_USER environment variable passed through by your devcontainer definition to deconflict your state backend with other sandbox developers. This value was then used directly in the root `terragrunt.hcl` and also passed in to `dependency/terragrunt.hcl` through an exposed include.

And now the command runs and we see plans successfully appear which predict the output of the terragrunt configs for `nested` and `dependency` - but then... an error!
```ERRO[0009] Module /workspaces/hello-terragrunt/backends/root/vpc has finished with an error: /workspaces/hello-terragrunt/backends/root/dependency/terragrunt.hcl is a dependency of /workspaces/hello-terragrunt/backends/root/vpc/terragrunt.hcl but detected no outputs.```

This error has occurred because the `vpc` config is attempting to pull remote state from the `dependency` config under the hood, but because it has not been applied there is not yet any remote state available. In a later section we will see a convention we can use to plan in the absence of a dependency. For now we will just continue and use `run-all apply`. Note that we are doing this as an exercise in understanding how terragrunt functions, rather than an exercise in best-practices.

So now we go ahead and run `terragrunt run-all apply`. We answer `y` to applying the external dependency and to blindly applying the modules in group 1 and group 2.

This time the command succeeds and the passthrough configs (`dependency` and `nested`) are created, as is the VPC. It's worth noting that the passthroughs were applied in parralel and completed at about the same time, and that the VPC was created after. This is because the dependency graph optimized the ordering of applies so that the most work could be done in parallel. We can also note that there was no failure this time - because completing the `dependency` apply made the remote state output available before `vpc` needed to consume it.

If we look in AWS (through console browsing or commands such as `aws s3 ls | grep $HOST_USER`) we will see that the backends exist, and that they contain unique state for each independent config.

Next we will remove our VPC with `terragrunt run-all destroy` - again answering `y` when prompted.

From this operation we can notice an important difference between `run-all plan/apply` and `run-all destroy` - the dependency is not destroyed. We would have to `cd ../dependency` and `terragrunt destroy` to destroy that config.

Two other important items to note after this exercise are:
- The state backends are not automatically deleted when we use `run-all destroy`
- The config for `dependency/notrun` was never created in the first place - this is because `run-all` will apply nested directories _and_ dependencies, but not nested directories _of_ dependencies.

Feel free to manually clean up the remaining remote state to conclude this exercise.
