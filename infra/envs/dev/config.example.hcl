# Modelo do config.hcl: copie para config.hcl (mesma pasta) e preencha com os valores da conta.
# O root.hcl e os units leem tudo daqui; nada específico de conta fica nos terragrunt.hcl.
locals {
  # Conta e região. O state vai para o bucket terragrunt-tf-state-<account_name>, e o provider
  # recusa operar em qualquer conta diferente de aws_account_id.
  account_name   = "" # ex.: minha-conta-dev
  aws_account_id = "" # ex.: 123456789012
  environment    = "" # ex.: dev (sufixo dos nomes e tag Env)
  aws_region     = "" # ex.: us-east-1

  # Prefixo dos nomes globais (buckets S3 precisam ser únicos em toda a AWS):
  # <name_prefix>-observability-<environment>-loki
  name_prefix = "" # ex.: minhaempresa
  department  = "" # tag Department, ex.: SRE

  # Rede onde as tasks rodam (subnets privadas). O CIDR libera as portas internas do Service Connect.
  vpc_id         = "" # ex.: vpc-0123456789abcdef0
  vpc_cidr_block = "" # ex.: 10.0.0.0/16
  subnet_ids     = [] # ex.: ["subnet-aaa", "subnet-bbb"]

  # ALB interno já existente (lido por nome) e zona privada do Route53 onde entram os registros
  # otel.<domain> (collector) e observability.<domain> (Grafana).
  alb_name                   = "" # ex.: meu-alb-interno
  alb_listener_priority_base = 0  # primeira prioridade livre no listener HTTP:80; usa base e base+10
  domain                     = "" # ex.: dev.internal
}
