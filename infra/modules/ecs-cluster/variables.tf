variable "cluster_name" {
  description = "Nome base do cluster (o env é acrescentado)"
  type        = string
}

variable "env" {
  description = "Ambiente (sufixo do nome e tag Env)"
  type        = string
}

variable "department" {
  description = "Time dono (tag Department)"
  type        = string
}

variable "container_insights" {
  description = "enabled, enhanced ou disabled"
  type        = string
  default     = "disabled"
}

variable "log_retention_days" {
  description = "Retenção do log group do cluster"
  type        = number
  default     = 30
}

variable "create_service_connect_namespace" {
  description = "Cria o namespace HTTP do Service Connect"
  type        = bool
  default     = false
}
