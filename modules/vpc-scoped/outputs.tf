# IAM

output "iam_roles" {
  value = module.iam_roles
}

# Security Groups

output "security_groups" {
  value = module.security_groups
}

# AWS Lambdas

output "lambda_rds_oracle_execute_sql_statements" {
  value = module.lambda_rds_oracle_execute_sql_statements
}

output "lambda_rds_oracle_update_users_credentials" {
  value = module.lambda_rds_oracle_update_users_credentials
}

output "lambda_valkey_clear_cache" {
  value = module.lambda_valkey_clear_cache
}

output "lambda_secretsmanager_rds_oracle_password_rotation" {
  value = module.lambda_secretsmanager_rds_oracle_password_rotation
}

output "lambda_secretsmanager_rds_mysql_password_rotation" {
  value = module.lambda_secretsmanager_rds_mysql_password_rotation
}

# Step Functions

output "step_functions" {
  value = module.step_functions
}

# Valkey

output "elasticache_valkey" {
  value = (
    length(module.elasticache_valkey) == 0
    ? null
    : contains(keys(module.elasticache_valkey), "main")
    ? module.elasticache_valkey["main"]
    : values(module.elasticache_valkey)[0]
  )
}

output "elasticache_valkey_all" {
  description = "All Valkey module instances (keyed by valkeys map key)"
  value       = module.elasticache_valkey
}

# ECS Cluster Outputs

output "ecs_cluster_arn" {
  value = module.ecs_cluster.arn
}

output "ecs_cluster_id" {
  value = module.ecs_cluster.id
}

output "ecs_cluster_name" {
  value = module.ecs_cluster.name
}

output "ecs_cluster_security_group_id" {
  value = try(module.ecs_cluster.security_group_id, null)
}

output "ecs_cluster_cloud_map_namespace_id" {
  value = try(aws_service_discovery_private_dns_namespace.ecs_cluster[0].id, null)
}

output "ecs_cluster_cloud_map_namespace_arn" {
  value = try(aws_service_discovery_private_dns_namespace.ecs_cluster[0].arn, null)
}

output "ecs_cluster_cloud_map_namespace_name" {
  value = try(aws_service_discovery_private_dns_namespace.ecs_cluster[0].name, null)
}

output "ecs_cluster_capacity_provider_names" {
  value = try({
    for name, provider in module.ecs_cluster.capacity_providers : name => provider.name
  }, {})
}

# Load Balancer (ALB) - Outputs

output "albs" {
  description = "Application Load Balancer attributes keyed by schema (public/private)."
  value = {
    for schema, lb in module.alb : schema => {
      id                 = lb.id
      arn                = lb.arn
      arn_suffix         = lb.arn_suffix
      dns_name           = lb.dns_name
      zone_id            = lb.zone_id
      listeners          = lb.listeners
      listener_rules     = lb.listener_rules
      security_group_id  = lb.security_group_id
      security_group_arn = lb.security_group_arn
    }
  }
}

output "alb" {
  description = "Primary Application Load Balancer attributes. Returns the internal ALB when both schemas are created."
  value = (
    contains(keys(module.alb), "internal")
    ? module.alb["internal"]
    : try(values(module.alb)[0], null)
  )
}

output "alb_arn" {
  value = {
    for schema, lb in module.alb : schema => lb.arn
  }
}

output "alb_dns_name" {
  value = {
    for schema, lb in module.alb : schema => lb.dns_name
  }
}

output "alb_zone_id" {
  value = {
    for schema, lb in module.alb : schema => lb.zone_id
  }
}

output "alb_security_group_id" {
  value = {
    for schema, lb in module.alb : schema => lb.security_group_id
  }
}

output "alb_primary_security_group_id" {
  description = "Security group ID of the primary ALB (internal if exists, otherwise public)."
  value = (
    contains(keys(module.alb), "internal")
    ? module.alb["internal"].security_group_id
    : try(values(module.alb)[0].security_group_id, null)
  )
}

output "alb_listener_arn" {
  description = "Map of listener ARNs keyed by schema and listener name. Example: alb_listener_arn[\"public\"][\"https\"]"
  value = {
    for schema, lb in module.alb : schema => {
      for listener_name, listener in lb.listeners : listener_name => listener.arn
    }
  }
}

output "alb_primary_listener_arn" {
  description = "Listener ARNs of the primary ALB (internal if exists, otherwise public). Example: alb_primary_listener_arn[\"https\"]"
  value = {
    for listener_name, listener in(
      contains(keys(module.alb), "internal")
      ? module.alb["internal"].listeners
      : try(values(module.alb)[0].listeners, {})
    ) : listener_name => listener.arn
  }
}