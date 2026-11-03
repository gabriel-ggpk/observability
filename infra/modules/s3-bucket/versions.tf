terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.41" # mínimo exigido pelos módulos terraform-aws-modules atuais
    }
  }
}
