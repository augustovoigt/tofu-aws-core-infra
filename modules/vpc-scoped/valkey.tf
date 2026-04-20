# AWS Elasticache Valkey

locals {
  valkeys_default = {
    main = {
      create = var.create_valkey

      # General
      replication_group_id = "${var.resource_prefix}-valkey"
      description          = "Elasticache Valkey service used by App HTML5 of all environments."

      # Engine and Node Type
      engine         = "valkey"
      engine_version = var.valkey_engine_version
      node_type      = var.valkey_node_type

      # Multi AZ
      multi_az_enabled           = var.valkey_multi_az
      num_cache_clusters         = var.valkey_multi_az ? 2 : 1
      automatic_failover_enabled = var.valkey_multi_az

      # Encryption
      at_rest_encryption_enabled = true
      transit_encryption_enabled = true
      transit_encryption_mode    = "required"

      # Maintenance
      maintenance_window       = var.valkey_maintenance_window
      apply_immediately        = true
      snapshot_retention_limit = 0

      # VPC
      vpc_id = var.vpc_id

      # Security Group
      create_security_group = var.create_valkey_security_group
      security_group_ids    = var.create_valkey_security_group ? [] : (var.elasticache_security_group_id != null ? [var.elasticache_security_group_id] : [])

      # Subnet Group
      create_subnet_group = var.create_valkey_subnet_group
      subnet_group_name   = var.create_valkey_subnet_group ? null : var.elasticache_subnet_group_name
      subnet_ids          = var.create_valkey_subnet_group ? var.private_subnet_ids : []

      # Parameter Group
      create_parameter_group = true
      parameter_group_name   = "${var.resource_prefix}-pg-valkey8"
      parameter_group_family = "valkey8"
      parameters = [
        {
          name  = "latency-tracking"
          value = "yes"
        }
      ]

      # Tags
      tags = {
        Name = "${var.resource_prefix}-valkey"
      }
    }
  }

  valkeys = merge(local.valkeys_default, var.valkeys)

  valkeys_enabled = {
    for key, valkey in local.valkeys : key => valkey
    if try(valkey.create, true)
  }
}

module "elasticache_valkey" {
  for_each = local.valkeys_enabled

  source  = "terraform-aws-modules/elasticache/aws"
  version = "1.11.0"

  replication_group_id = each.value.replication_group_id
  description          = each.value.description

  engine         = each.value.engine
  engine_version = each.value.engine_version
  node_type      = each.value.node_type

  multi_az_enabled           = each.value.multi_az_enabled
  num_cache_clusters         = each.value.num_cache_clusters
  automatic_failover_enabled = each.value.automatic_failover_enabled

  at_rest_encryption_enabled = each.value.at_rest_encryption_enabled
  transit_encryption_enabled = each.value.transit_encryption_enabled
  transit_encryption_mode    = each.value.transit_encryption_mode

  maintenance_window       = each.value.maintenance_window
  apply_immediately        = each.value.apply_immediately
  snapshot_retention_limit = each.value.snapshot_retention_limit

  vpc_id = each.value.vpc_id

  create_security_group = each.value.create_security_group
  security_group_ids    = each.value.security_group_ids

  create_subnet_group = each.value.create_subnet_group
  subnet_group_name   = each.value.subnet_group_name
  subnet_ids          = try(each.value.subnet_ids, [])

  create_parameter_group = each.value.create_parameter_group
  parameter_group_name   = each.value.parameter_group_name
  parameter_group_family = each.value.parameter_group_family
  parameters             = each.value.parameters

  tags = each.value.tags
}

resource "aws_vpc_security_group_ingress_rule" "valkey_from_service_base" {
  count = var.create_valkey_security_group && var.aws_service_base_security_group_id != null ? 1 : 0

  security_group_id            = module.elasticache_valkey["main"].security_group_id
  referenced_security_group_id = var.aws_service_base_security_group_id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  description                  = "Allow Valkey connections from AWS service base (Lambdas)."
}
