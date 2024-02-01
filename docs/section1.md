# Section 1 - Creating the devcontainer and hello world file

In this section we bring in a dev container and the basic hello world terragrunt.hcl to bring us to the `section1` tag.

## First Hello

The devcontainer is a go and python base with a small collection of utilities for terraform, terragrunt, and kubernetes.

The devcontainer mounts `~/.aws` to allow for authentication to pass through from the host.

The hello world file comes from the gruntwork quickstart [example](https://terragrunt.gruntwork.io/docs/getting-started/quick-start/#example). The content was modified to use the latest version of the [vpc module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/5.5.1) as the currently listed version on the gruntwork site is broken.

To run the content so far with local terraform state we log in to our AWS sandbox, enter the `hello` directory, and `terragrunt apply`.

After answering yes to the prompt we will have applied our first terraform content through terragrunt.
