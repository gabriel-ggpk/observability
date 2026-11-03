data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  name = "${var.service_name}-${var.env}"
  tags = {
    Env        = var.env
    Department = var.department
  }

  use_alb    = var.alb_name != null
  create_dns = local.use_alb && var.route53_zone_name != null && var.route53_record_name != null
  # Health check numa porta própria (ex.: collector responde em 13133, não na 4318)
  custom_health_port = local.use_alb && var.alb_health_check_port != "traffic-port"

  # Cada porta extra vira um port mapping nomeado "<serviço>-<nome>" (ex.: tempo-otlp)
  extra_ports = { for p in var.additional_ports : p.name => p.port }
}

# ---------------------------------------------------------------------------
# ALB compartilhado e zona privada: lidos por nome, não são nossos
# ---------------------------------------------------------------------------

data "aws_lb" "shared" {
  count = local.use_alb ? 1 : 0
  name  = var.alb_name
}

data "aws_lb_listener" "shared" {
  count             = local.use_alb ? 1 : 0
  load_balancer_arn = data.aws_lb.shared[0].arn
  port              = var.alb_listener_port
}

data "aws_route53_zone" "shared" {
  count        = local.create_dns ? 1 : 0
  name         = var.route53_zone_name
  private_zone = true
}

# ---------------------------------------------------------------------------
# Serviço ECS: task definition, roles, security group e service
# ---------------------------------------------------------------------------

module "service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 7.6"

  name        = local.name
  cluster_arn = var.cluster_id

  cpu    = var.cpu
  memory = var.memory
  runtime_platform = {
    cpu_architecture        = var.cpu_architecture
    operating_system_family = "LINUX"
  }

  desired_count = var.desired_count
  # Os backends são monolíticos com ring em memória: réplica extra quebraria o estado
  enable_autoscaling = false

  container_definitions = {
    # Chave fixa ("app") para que o endereço no state não dependa do nome do serviço
    app = {
      name      = var.service_name
      image     = var.image_uri
      essential = true
      # Loki, Tempo, Mimir e Grafana gravam em disco local (WAL, SQLite)
      readonlyRootFilesystem = false

      portMappings = concat(
        var.container_port != null ? [{
          name          = var.service_name
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }] : [],
        [for name, port in local.extra_ports : {
          name          = "${var.service_name}-${name}"
          containerPort = port
          hostPort      = port
          protocol      = "tcp"
        }]
      )

      environment = [for k, v in var.environment_variables : { name = k, value = v }]
      secrets     = [for k, v in var.secrets : { name = k, valueFrom = v }]

      cloudwatch_log_group_name              = "/ecs/${local.name}"
      cloudwatch_log_group_retention_in_days = var.log_retention_days
    }
  }

  # Mesmos nomes das roles de antes, para o moved não precisar recriá-las
  task_exec_iam_role_name            = "${local.name}-execution-role"
  task_exec_iam_role_use_name_prefix = false
  tasks_iam_role_name                = "${local.name}-task-role"
  tasks_iam_role_use_name_prefix     = false

  # Execution role lê só os parâmetros SSM que a task usa (antes era "*")
  task_exec_ssm_param_arns = [
    for v in values(var.secrets) :
    "arn:aws:ssm:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:parameter${v}"
  ]

  subnet_ids       = var.subnet_ids
  vpc_id           = var.vpc_id
  assign_public_ip = var.assign_public_ip

  # Regras separadas (aws_vpc_security_group_*_rule) em vez de blocos inline
  security_group_ingress_rules = merge(
    # Porta principal: só do ALB quando há ALB; senão, da VPC (Service Connect)
    var.container_port == null ? {} : (
      local.use_alb
      ? { for i, sg in tolist(data.aws_lb.shared[0].security_groups) : "alb-${i}" => {
        description                  = "Container port from shared ALB"
        from_port                    = var.container_port
        referenced_security_group_id = sg
      } }
      : { vpc = {
        description = "Container port from VPC"
        from_port   = var.container_port
        cidr_ipv4   = var.vpc_cidr_block
      } }
    ),
    { for name, port in local.extra_ports : "extra-${name}" => {
      description = "Additional port ${name} from VPC"
      from_port   = port
      cidr_ipv4   = var.vpc_cidr_block
    } },
    local.custom_health_port
    ? { for i, sg in tolist(data.aws_lb.shared[0].security_groups) : "alb-health-${i}" => {
      description                  = "ALB health checks on dedicated port"
      from_port                    = tonumber(var.alb_health_check_port)
      referenced_security_group_id = sg
    } }
    : {}
  )
  security_group_egress_rules = {
    all = {
      description = "Allow all outbound"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  load_balancer = local.use_alb && var.container_port != null ? {
    alb = {
      # Via regra do listener: o service só é criado depois que o TG está ligado ao ALB
      target_group_arn = aws_lb_listener_rule.this[0].action[0].target_group_arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  } : null

  service_connect_configuration = var.enable_service_connect && var.container_port != null ? {
    namespace = var.service_connect_namespace
    service = concat(
      [{
        port_name      = var.service_name
        discovery_name = var.service_name
        client_alias   = { port = var.container_port, dns_name = var.service_name }
      }],
      # Cada porta extra é um serviço próprio no Cloud Map (nomes únicos no namespace)
      [for name, port in local.extra_ports : {
        port_name      = "${var.service_name}-${name}"
        discovery_name = "${var.service_name}-${name}"
        client_alias   = { port = port, dns_name = "${var.service_name}-${name}" }
      }]
    )
  } : null

  tags = local.tags
}

# Permissões extras da aplicação (ex.: S3 do backend). Recurso fora do módulo para manter
# o mesmo endereço e nome da policy inline de antes.
resource "aws_iam_role_policy" "task_extra" {
  count  = var.task_role_policy_json != null ? 1 : 0
  name   = "${local.name}-task-policy"
  role   = module.service.tasks_iam_role_name
  policy = var.task_role_policy_json
}

# ---------------------------------------------------------------------------
# Integração com o ALB compartilhado: o módulo de service só recebe um target group
# pronto, então target group, regra no listener e DNS ficam aqui
# ---------------------------------------------------------------------------

resource "aws_lb_target_group" "this" {
  count       = local.use_alb ? 1 : 0
  name        = substr("${local.name}-tg", 0, 32) # limite de 32 caracteres
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.alb_health_check_path
    port                = var.alb_health_check_port
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 10
    matcher             = "200-399"
  }

  tags = merge(local.tags, { Name = substr("${local.name}-tg", 0, 32) })
}

resource "aws_lb_listener_rule" "this" {
  count        = local.use_alb ? 1 : 0
  listener_arn = data.aws_lb_listener.shared[0].arn
  priority     = var.alb_listener_priority

  condition {
    host_header {
      values = var.alb_host_headers
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }
}

resource "aws_route53_record" "this" {
  count   = local.create_dns ? 1 : 0
  zone_id = data.aws_route53_zone.shared[0].zone_id
  name    = var.route53_record_name
  type    = "A"

  alias {
    name                   = data.aws_lb.shared[0].dns_name
    zone_id                = data.aws_lb.shared[0].zone_id
    evaluate_target_health = true
  }
}
