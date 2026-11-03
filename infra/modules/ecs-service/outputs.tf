output "service_name" {
  description = "Nome do serviço ECS"
  value       = module.service.name
}

output "task_definition_arn" {
  description = "ARN da última revisão da task definition"
  value       = module.service.task_definition_arn
}

output "task_role_arn" {
  description = "ARN da task role"
  value       = module.service.tasks_iam_role_arn
}

output "security_group_id" {
  description = "Security group das tasks"
  value       = module.service.security_group_id
}

output "target_group_arn" {
  description = "Target group no ALB (null sem ALB)"
  value       = try(aws_lb_target_group.this[0].arn, null)
}
