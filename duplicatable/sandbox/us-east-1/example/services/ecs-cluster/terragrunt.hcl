include "root" {
  path = find_in_parent_folders()
}

# We introduce this dependency just to ensure the user gets an interactive prompt without competing text.
dependencies {
  paths = ["../../../../_global/network/subdomain"]
}

# Include the envcommon configuration for the component. The envcommon configuration contains settings that are common
# for the component across all environments.
include "envcommon" {
  path = "${dirname(find_in_parent_folders())}/_envcommon/ecs-cluster.hcl"
}
