output "repository_url" {
  description = "URL do repositório (base do image_uri nas task definitions)"
  value       = module.ecr.repository_url
}

output "repository_arn" {
  description = "ARN do repositório"
  value       = module.ecr.repository_arn
}
