locals {
  alb_fixed_response_default = {
    content_type = "text/plain"
    message_body = "Service Unavailable"
    status_code  = "503"
  }

  # alb_listeners_base = {
  #   http-8080 = {
  #     port           = 8080
  #     protocol       = "HTTP"
  #     fixed_response = local.alb_fixed_response_default
  #   }
  #   http-3069 = {
  #     port           = 3069
  #     protocol       = "HTTP"
  #     fixed_response = local.alb_fixed_response_default
  #   }
  # }
  alb_listeners_base = {}

  alb_public_listeners = merge(
    var.alb_public_certificate_arn != null ? {
      https = {
        port            = 443
        protocol        = "HTTPS"
        ssl_policy      = ""
        certificate_arn = var.alb_public_certificate_arn
        fixed_response  = local.alb_fixed_response_default
      }
    } : {},
    local.alb_listeners_base
  )

  alb_internal_listeners = merge(
    var.alb_internal_certificate_arn != null ? {
      https = {
        port            = 443
        protocol        = "HTTPS"
        ssl_policy      = ""
        certificate_arn = var.alb_internal_certificate_arn
        fixed_response  = local.alb_fixed_response_default
      }
    } : {},
    local.alb_listeners_base
  )

  alb_security_group_egress_rules_default = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  alb_default = {
    public = {
      create   = var.create_alb_public
      internal = false

      subnet_ids = var.public_subnet_ids
      listeners  = local.alb_public_listeners
    }

    internal = {
      create   = var.create_alb_internal
      internal = true

      subnet_ids = var.private_subnet_ids
      listeners  = local.alb_internal_listeners
    }
  }

  albs = {
    for k, v in merge(local.alb_default, var.albs) : k => merge({
      idle_timeout               = var.alb_idle_timeout
      enable_http2               = var.alb_enable_http2
      enable_deletion_protection = var.alb_enable_deletion_protection

      create_security_group        = true
      security_group_ids           = []
      security_group_ingress_rules = {}
      security_group_egress_rules  = local.alb_security_group_egress_rules_default

      access_logs = var.alb_access_logs
    }, v)
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.5.0"

  for_each = { for k, v in local.albs : k => v if try(v.create, false) }

  name                       = "${var.resource_prefix}-${each.key}-alb"
  load_balancer_type         = "application"
  internal                   = each.value.internal
  idle_timeout               = each.value.idle_timeout
  enable_http2               = each.value.enable_http2
  enable_deletion_protection = each.value.enable_deletion_protection
  vpc_id                     = var.vpc_id
  subnets                    = each.value.subnet_ids

  create_security_group = each.value.create_security_group
  security_groups = compact(concat(
    coalesce(try(each.value.security_group_ids, []), []),
    each.value.internal ? try([module.security_groups["internal"].security_group_id], []) : [],
    !each.value.internal ? try([module.security_groups["external"].security_group_id], []) : []
  ))

  security_group_name            = "${var.resource_prefix}-${each.key}-alb-sg"
  security_group_use_name_prefix = false
  security_group_description     = "Security group for ${var.resource_prefix} ${each.key} application load balancer"
  security_group_tags = {
    Name = "${var.resource_prefix}-${each.key}-alb-sg"
  }

  security_group_ingress_rules = {
    for name, rule in coalesce(try(each.value.security_group_ingress_rules, {}), {}) : name => merge(rule, {
      to_port = try(rule.to_port, rule.from_port)
    })
  }
  security_group_egress_rules = each.value.security_group_egress_rules

  access_logs = (
    try(each.value.access_logs, null) != null && trimspace(try(each.value.access_logs.bucket, "")) != ""
    ? {
      bucket  = each.value.access_logs.bucket
      enabled = try(each.value.access_logs.enabled, true)
      prefix  = try(each.value.access_logs.prefix, null)
    }
    : null
  )

  listeners = each.value.listeners

  tags = {
    Name = "${var.resource_prefix}-${each.key}-alb"
  }
}