include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true # permite ler include.root.locals.config (valores da conta) neste arquivo
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/modules/s3-bucket"
}

# Bucket próprio: métricas têm retenção e permissões independentes de logs e traces
inputs = {
  bucket_name = "${include.root.locals.config.name_prefix}-observability-${include.root.locals.config.environment}-mimir"
}
