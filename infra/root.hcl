# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform/OpenTofu that provides extra tools for working with multiple modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Tudo o que é específico da conta/ambiente vem do config.hcl do ambiente (envs/<env>/config.hcl).
  # Units com `expose = true` no include leem os valores como include.root.locals.config.<chave>.
  config = read_terragrunt_config(find_in_parent_folders("config.hcl")).locals

  account_name = local.config.account_name
  account_id   = local.config.aws_account_id
  aws_region   = local.config.aws_region
}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  # Only these AWS Account IDs may be operated on by this template
  allowed_account_ids = ["${local.account_id}"]
}
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    encrypt      = true
    bucket       = "${get_env("TG_BUCKET_PREFIX", "")}terragrunt-tf-state-${local.account_name}"
    key          = "${path_relative_to_include()}/tf.tfstate"
    region       = local.aws_region
    use_lockfile = true
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

# Inputs comuns a todos os units. Os que um módulo não declara são ignorados (ex.: o ECR não usa vpc_id).
inputs = {
  env            = local.config.environment
  department     = local.config.department
  vpc_id         = local.config.vpc_id
  vpc_cidr_block = local.config.vpc_cidr_block
  subnet_ids     = local.config.subnet_ids
}
