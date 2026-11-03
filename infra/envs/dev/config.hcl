# Set account-wide variables. These are automatically pulled in to configure the remote state bucket in the root
# terragrunt.hcl configuration.
locals {
  account_name   = ""
  aws_account_id = ""
  environment    = ""
  aws_region     = ""
}
