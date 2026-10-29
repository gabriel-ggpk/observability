include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/aca-so/terraform-modules.git//ecs/cluster?ref=main"
}

inputs = {
  cluster_name               = "observability"
  env                        = "dev"
  department                 = "SRE"
  container_insights = "enhanced"
  log_retention_days         = 14
  create_service_connect_namespace = true
}
