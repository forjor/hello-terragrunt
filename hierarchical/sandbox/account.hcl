locals {
  username       = get_env("HOST_USER", "unknown")
  account_name   = "sandbox-${split(".", local.username)[0]}"
}
