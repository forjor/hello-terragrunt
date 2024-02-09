locals {
  full_path_to_directory = get_path_from_repo_root()
  environment            = reverse(split("/", local.full_path_to_directory))[0]
  primary_environment    = "example"
}
