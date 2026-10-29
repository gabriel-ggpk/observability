include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/aca-so/terraform-modules.git//ecr/repository?ref=main"
}

inputs = {
  repository_name = "observability-tempo"
  env             = "dev"
  department      = "SRE"
  max_image_count = 5
}
