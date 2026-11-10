include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true # permite ler include.root.locals.config (valores da conta) neste arquivo
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/modules/ecs-service"
}

dependency "cluster" {
  config_path                             = "../../cluster"
  mock_outputs                            = { cluster_id = "mock", service_connect_namespace_arn = "arn:aws:servicediscovery:us-east-1:000000000000:namespace/mock" }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}
dependency "ecr" {
  config_path                             = "../ecr"
  mock_outputs                            = { repository_url = "mock" }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  service_name = "otel-collector"

  cluster_id       = dependency.cluster.outputs.cluster_id
  image_uri        = dependency.ecr.outputs.repository_url
  cpu              = 512
  memory           = 1024
  cpu_architecture = "ARM64"
  container_port   = 4318

  alb_name              = include.root.locals.config.alb_name
  alb_listener_priority = include.root.locals.config.alb_listener_priority_base # única no listener
  alb_host_headers      = ["otel.${include.root.locals.config.domain}"]
  alb_health_check_path = "/"
  alb_health_check_port = 13133

  route53_zone_name   = include.root.locals.config.domain
  route53_record_name = "otel.${include.root.locals.config.domain}"

  enable_service_connect    = true
  service_connect_namespace = dependency.cluster.outputs.service_connect_namespace_arn
}