# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform and OpenTofu that helps keep your code DRY and
# maintainable: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

# Include the root `terragrunt.hcl` configuration. The root configuration contains settings that are common across all
# components and environments, such as how to configure remote state.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source  = "git::https://github.com/aca-so/terraform-modules.git//security-group?ref=main"
}

inputs = {
  vpc_name = "dev-env"
  security_group_name = "database-security-group"
  env = "dev"
  department = "dev"
  ingress_ipv4_from_port = "5432"
  ingress_ipv4_to_port = "5432"
  ingress_ipv4_protocol = "tcp"
  ingress_ipv4_cidr_blocks = ["10.2.0.0/16"]

  egress_from_port = "0"
  egress_to_port = "0"
  egress_protocol = "-1"
  egress_cidr_blocks = ["0.0.0.0/0"]
}

