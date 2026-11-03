output "bucket_name" {
  description = "Nome do bucket"
  value       = module.bucket.s3_bucket_id
}

output "bucket_arn" {
  description = "ARN do bucket"
  value       = module.bucket.s3_bucket_arn
}
