include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/modules/s3-bucket"
}

# Bucket próprio: métricas têm retenção e permissões independentes de logs e traces
inputs = {
  bucket_name = "acaso-observability-dev-mimir"
  env         = "dev"
  department  = "SRE"
}
