# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform and OpenTofu that helps keep your code DRY and
# maintainable: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# Include the root `terragrunt.hcl` configuration. The root configuration contains settings that are common across all
# components and environments, such as how to configure remote state.
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true # permite ler include.root.locals.config (valores da conta) neste arquivo
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/modules/s3-bucket"
}

inputs = {
  bucket_name = "${include.root.locals.config.name_prefix}-observability-${include.root.locals.config.environment}-loki"
}