locals {
  username     = get_env("HOST_USER", "unknown")
  usershort    = split(".", local.username)[0]
  account_name = "sandbox-${local.usershort}"
}
