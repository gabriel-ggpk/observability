include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/aca-so/terraform-modules.git//ecs/backend-service?ref=main"
}


dependency "cluster" {
  config_path = "../../cluster"
  mock_outputs = { cluster_id = "mock", service_connect_namespace_arn = "arn:aws:servicediscovery:us-east-1:000000000000:namespace/mock" }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}
dependency "ecr" {
  config_path = "../ecr"
  mock_outputs = { repository_url = "mock" }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  service_name     = "otel-collector"
  env          = "dev"
  department   = "SRE"

  vpc_id         = "vpc-0a91fbffb2f8c86cb"
  vpc_cidr_block = "10.2.0.0/16"
  subnet_ids     = ["subnet-0f2905459d06a9914", "subnet-0a6197680683c2d96"]

  cluster_id       = dependency.cluster.outputs.cluster_id
  image_uri        = dependency.ecr.outputs.repository_url
  cpu              = 512
  memory           = 1024
  cpu_architecture = "ARM64"
  container_port   = 4318

  alb_name              = "datascience-dev-internal"
  alb_listener_priority = 210                      # única no listener
  alb_host_headers      = ["otel.acaso.dev.internal"]
  alb_health_check_path = "/"
  alb_health_check_port = 13133

  route53_zone_name   = "acaso.dev.internal"
  route53_record_name = "otel.acaso.dev.internal"

  enable_service_connect    = true
  service_connect_namespace = dependency.cluster.outputs.service_connect_namespace_arn
  # + vpc_id, vpc_cidr_block, subnet_ids, env, department
}