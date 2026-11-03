# Repositório ECR privado com os padrões da stack: tag mutável (:latest), scan no push,
# criptografia AES256 e expiração de imagens antigas.
module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 3.2"

  repository_name                 = var.repository_name
  repository_image_tag_mutability = var.image_tag_mutability
  repository_image_scan_on_push   = true
  # Explícito: mudar o tipo de criptografia recria o repositório (e apaga as imagens)
  repository_encryption_type = "AES256"

  # Sem repository policy: só a própria conta acessa, via IAM
  create_repository_policy = false
  attach_repository_policy = false

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} sha-prefixed images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["sha-"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      }
    ]
  })

  tags = {
    Name       = var.repository_name
    Env        = var.env
    Department = var.department
  }
}
