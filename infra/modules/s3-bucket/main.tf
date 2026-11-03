# Bucket privado para os backends (Loki, Tempo, Mimir). Acesso só via IAM (task role).
module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.17"

  bucket = var.bucket_name

  # block_public_* já vêm true por padrão no módulo
  # ACLs desligadas: o dono do bucket é dono de todos os objetos
  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  # Recusa qualquer request sem TLS (os SDKs dos backends já usam HTTPS)
  attach_deny_insecure_transport_policy = true

  tags = {
    Name       = var.bucket_name
    Env        = var.env
    Department = var.department
  }
}
