include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/aca-so/terraform-modules.git//s3/basic?ref=main"
}

# Bucket separado do Loki: permissões e retenção independentes por sinal
inputs = {
  bucket_name = "acaso-observability-dev-tempo"
  env         = "dev"
  department  = "SRE"
}
