variable "repository_name" {
  description = "Nome do repositório ECR"
  type        = string
}

variable "env" {
  description = "Ambiente (tag Env)"
  type        = string
}

variable "department" {
  description = "Time dono (tag Department)"
  type        = string
}

variable "image_tag_mutability" {
  description = "MUTABLE permite sobrescrever :latest"
  type        = string
  default     = "MUTABLE"
}

variable "max_image_count" {
  description = "Quantas imagens sha-* manter"
  type        = number
  default     = 30
}
