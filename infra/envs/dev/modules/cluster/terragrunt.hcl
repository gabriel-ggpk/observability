include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/modules/ecs-cluster"
}

inputs = {
  cluster_name               = "observability"
  env                        = "dev"
  department                 = "SRE"
  container_insights = "enhanced"
  log_retention_days         = 14
  create_service_connect_namespace = true
}
