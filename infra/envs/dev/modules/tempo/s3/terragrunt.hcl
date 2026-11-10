include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true # permite ler include.root.locals.config (valores da conta) neste arquivo
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/modules/s3-bucket"
}

# Bucket separado do Loki: permissões e retenção independentes por sinal
inputs = {
  bucket_name = "${include.root.locals.config.name_prefix}-observability-${include.root.locals.config.environment}-tempo"
}
