locals {
  name = "${var.cluster_name}-${var.env}"
  tags = {
    Env        = var.env
    Department = var.department
  }
}

module "cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 7.6"

  name = local.name

  setting = [{
    name  = "containerInsights"
    value = var.container_insights
  }]

  # Log group do cluster: o módulo o usa para os logs de ECS Exec
  cloudwatch_log_group_name              = "/ecs/${local.name}"
  cloudwatch_log_group_retention_in_days = var.log_retention_days

  # Namespace padrão do cluster: services que ligam o Service Connect sem informar
  # namespace caem neste
  service_connect_defaults = var.create_service_connect_namespace ? {
    namespace = aws_service_discovery_http_namespace.service_connect[0].arn
  } : null

  tags = merge(local.tags, { Name = local.name })
}

# Namespace do Service Connect: o módulo do cluster só recebe o ARN (service_connect_defaults),
# não cria o namespace. Tipo HTTP = sem hosted zone do Route53; os nomes (loki, tempo, mimir)
# são resolvidos pelo proxy local de cada task.
resource "aws_service_discovery_http_namespace" "service_connect" {
  count = var.create_service_connect_namespace ? 1 : 0

  name        = local.name
  description = "Service Connect namespace for the ${local.name} ECS cluster"

  tags = merge(local.tags, { Name = local.name })
}
