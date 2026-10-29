include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true # permite ler include.root.locals (região) neste arquivo
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

dependency "s3" {
  config_path = "../s3"
  mock_outputs = { bucket_name = "mock-bucket", bucket_arn = "arn:aws:s3:::mock-bucket" }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  service_name = "tempo"
  env          = "dev"
  department   = "SRE"

  vpc_id         = "vpc-0a91fbffb2f8c86cb"
  vpc_cidr_block = "10.2.0.0/16"
  subnet_ids     = ["subnet-0f2905459d06a9914", "subnet-0a6197680683c2d96"]

  cluster_id       = dependency.cluster.outputs.cluster_id
  image_uri        = "${dependency.ecr.outputs.repository_url}:latest"
  cpu              = 1024
  memory           = 2048
  cpu_architecture = "ARM64"
  desired_count    = 1 # monolítico: tudo num processo, sem ring compartilhado

  # Duas portas, dois papéis. No Service Connect viram:
  #   tempo:3200      -> API de consulta (Grafana)
  #   tempo-otlp:4318 -> ingestão OTLP (collector)
  container_port   = 3200
  additional_ports = [{ name = "otlp", port = 4318 }]

  # Sem ALB: o Tempo só é acessado de dentro da VPC
  enable_service_connect    = true
  service_connect_namespace = dependency.cluster.outputs.service_connect_namespace_arn

  # Lidos pelo tempo.yaml via -config.expand-env=true
  environment_variables = {
    AWS_REGION      = include.root.locals.aws_region
    TEMPO_S3_BUCKET = dependency.s3.outputs.bucket_name
  }

  # Task role: só o necessário no bucket do Tempo
  task_role_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = dependency.s3.outputs.bucket_arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${dependency.s3.outputs.bucket_arn}/*"
      },
    ]
  })

  log_retention_days = 14
}
