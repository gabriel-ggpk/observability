include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/modules/ecr"
}

inputs = {
  repository_name = "observability-loki"
  env             = "dev"
  department      = "SRE"
  max_image_count = 5
}
