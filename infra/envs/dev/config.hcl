# Set account-wide variables. These are automatically pulled in to configure the remote state bucket in the root
# terragrunt.hcl configuration.
locals {
  account_name   = "selfinventory-dev"
  aws_account_id = "314146314711"
  environment    = "dev"
  aws_region     = "us-east-1"
}
