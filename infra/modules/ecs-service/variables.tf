variable "service_name" {
  description = "Nome do serviço; também é o nome do container e do Service Connect (ex.: loki)"
  type        = string
}

variable "env" {
  description = "Ambiente (sufixo dos nomes e tag Env)"
  type        = string
}

variable "department" {
  description = "Time dono (tag Department)"
  type        = string
}

variable "cluster_id" {
  description = "ARN do cluster ECS"
  type        = string
}

variable "vpc_id" {
  description = "VPC das tasks"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR liberado nas portas internas (Service Connect)"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets privadas das tasks"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "IP público nas tasks"
  type        = bool
  default     = false
}

variable "image_uri" {
  description = "Imagem do container"
  type        = string
}

variable "cpu" {
  description = "CPU da task (unidades de vCPU x 1024)"
  type        = number
}

variable "memory" {
  description = "Memória da task em MiB"
  type        = number
}

variable "cpu_architecture" {
  description = "X86_64 ou ARM64"
  type        = string
  default     = "X86_64"
}

variable "desired_count" {
  description = "Número de tasks"
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Porta principal (ALB e Service Connect)"
  type        = number
  default     = null
}

variable "additional_ports" {
  description = "Portas extras expostas no Service Connect como <serviço>-<name>"
  type = list(object({
    name = string
    port = number
  }))
  default = []
}

variable "environment_variables" {
  description = "Variáveis de ambiente do container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Mapa NOME_DA_VAR => nome do parâmetro SSM (ex.: /observability/dev/...)"
  type        = map(string)
  default     = {}
}

variable "task_role_policy_json" {
  description = "Policy JSON extra para a task role"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Retenção do log group do container"
  type        = number
  default     = 30
}

variable "enable_service_connect" {
  description = "Registra o serviço no namespace do Service Connect"
  type        = bool
  default     = false
}

variable "service_connect_namespace" {
  description = "ARN do namespace do Service Connect"
  type        = string
  default     = null
}

variable "alb_name" {
  description = "Nome do ALB compartilhado (null = sem ALB)"
  type        = string
  default     = null
}

variable "alb_listener_port" {
  description = "Porta do listener do ALB"
  type        = number
  default     = 80
}

variable "alb_listener_priority" {
  description = "Prioridade da regra no listener (única por listener)"
  type        = number
  default     = null
}

variable "alb_host_headers" {
  description = "Hosts roteados para este serviço"
  type        = list(string)
  default     = []
}

variable "alb_health_check_path" {
  description = "Path do health check do target group"
  type        = string
  default     = "/"
}

variable "alb_health_check_port" {
  description = "Porta do health check (traffic-port = a porta do container)"
  type        = string
  default     = "traffic-port"
}

variable "route53_zone_name" {
  description = "Zona privada do registro DNS"
  type        = string
  default     = null
}

variable "route53_record_name" {
  description = "Registro DNS apontando para o ALB"
  type        = string
  default     = null
}
