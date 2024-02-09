include "root" {
  path = find_in_parent_folders()
}

# We introduce this dependency just to ensure the user gets an interactive prompt without competing text.
dependencies {
  paths = ["../../../_global/network/subdomain"]
}
