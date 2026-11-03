include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/modules/s3-bucket"
}

# Bucket separado do Loki: permissões e retenção independentes por sinal
inputs = {
  bucket_name = "acaso-observability-dev-tempo"
  env         = "dev"
  department  = "SRE"
}
