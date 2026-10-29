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
  service_name = "grafana"
  env          = "dev"
  department   = "SRE"

  vpc_id         = "vpc-0a91fbffb2f8c86cb"
  vpc_cidr_block = "10.2.0.0/16"
  subnet_ids     = ["subnet-0f2905459d06a9914", "subnet-0a6197680683c2d96"]

  cluster_id       = dependency.cluster.outputs.cluster_id
  image_uri        = "${dependency.ecr.outputs.repository_url}:latest"
  cpu              = 512
  memory           = 1024
  cpu_architecture = "ARM64"
  container_port   = 3000
  desired_count    = 1 # SQLite local: duas tasks teriam bancos diferentes

  # Acesso humano pelo ALB interno (Tailscale). grafana.acaso.dev.internal já é do acaso-grafana.
  alb_name              = "datascience-dev-internal"
  alb_listener_priority = 220 # 100, 200 e 210 já estão em uso no listener
  alb_host_headers      = ["observability.acaso.dev.internal"]
  alb_health_check_path = "/api/health"

  route53_zone_name   = "acaso.dev.internal"
  route53_record_name = "observability.acaso.dev.internal"

  # Service Connect como cliente: é o que faz http://loki:3100 resolver dentro da task
  enable_service_connect    = true
  service_connect_namespace = dependency.cluster.outputs.service_connect_namespace_arn

  environment_variables = {
    GF_SERVER_ROOT_URL              = "http://observability.acaso.dev.internal"
    GF_SECURITY_ADMIN_USER          = "admin"
    GF_USERS_ALLOW_SIGN_UP          = "false"
    GF_ANALYTICS_REPORTING_ENABLED  = "false"
    GF_ANALYTICS_CHECK_FOR_UPDATES  = "false"
    GF_ANALYTICS_CHECK_FOR_PLUGIN_UPDATES = "false"
  }

  # Parâmetro SecureString criado fora do Terraform, para o valor não ir para o state
  secrets = {
    GF_SECURITY_ADMIN_PASSWORD = "/observability/dev/grafana/admin-password"
  }

  log_retention_days = 14
}
