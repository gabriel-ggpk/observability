output "cluster_id" {
  description = "ID do cluster (é o ARN)"
  value       = module.cluster.id
}

output "cluster_arn" {
  description = "ARN do cluster"
  value       = module.cluster.arn
}

output "cluster_name" {
  description = "Nome do cluster"
  value       = module.cluster.name
}

output "service_connect_namespace_arn" {
  description = "ARN do namespace do Service Connect (null se não criado)"
  value       = try(aws_service_discovery_http_namespace.service_connect[0].arn, null)
}
