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
  service_name = "grafana"

  cluster_id       = dependency.cluster.outputs.cluster_id
  image_uri        = "${dependency.ecr.outputs.repository_url}:latest"
  cpu              = 512
  memory           = 1024
  cpu_architecture = "ARM64"
  container_port   = 3000
  desired_count    = 1 # SQLite local: duas tasks teriam bancos diferentes

  # Acesso humano pelo ALB interno
  alb_name              = include.root.locals.config.alb_name
  alb_listener_priority = include.root.locals.config.alb_listener_priority_base + 10 # única no listener
  alb_host_headers      = ["observability.${include.root.locals.config.domain}"]
  alb_health_check_path = "/api/health"

  route53_zone_name   = include.root.locals.config.domain
  route53_record_name = "observability.${include.root.locals.config.domain}"

  # Service Connect como cliente: é o que faz http://loki:3100 resolver dentro da task
  enable_service_connect    = true
  service_connect_namespace = dependency.cluster.outputs.service_connect_namespace_arn

  environment_variables = {
    GF_SERVER_ROOT_URL                    = "http://observability.${include.root.locals.config.domain}"
    GF_SECURITY_ADMIN_USER                = "admin"
    GF_USERS_ALLOW_SIGN_UP                = "false"
    GF_ANALYTICS_REPORTING_ENABLED        = "false"
    GF_ANALYTICS_CHECK_FOR_UPDATES        = "false"
    GF_ANALYTICS_CHECK_FOR_PLUGIN_UPDATES = "false"
  }

  # Parâmetro SecureString criado fora do Terraform, para o valor não ir para o state
  secrets = {
    GF_SECURITY_ADMIN_PASSWORD = "/observability/${include.root.locals.config.environment}/grafana/admin-password"
  }

  log_retention_days = 14
}
