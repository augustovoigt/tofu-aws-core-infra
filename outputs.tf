# IAM roles (name collision between global and VPC Scoped)

output "iam_roles" {
  value = (
    var.context == "global" ? module.global[0].iam_roles :
    var.context == "vpc-scoped" ? module.vpc_scoped[0].iam_roles :
    null
  )
}

# Regional outputs

output "s3_buckets" {
  description = "Map of S3 buckets created"
  value       = var.context == "regional" ? module.regional[0].s3_buckets : null
}

output "s3_bucket_ids" {
  description = "Map of S3 bucket IDs"
  value       = var.context == "regional" ? module.regional[0].s3_bucket_ids : null
}

output "s3_bucket_arns" {
  description = "Map of S3 bucket ARNs"
  value       = var.context == "regional" ? module.regional[0].s3_bucket_arns : null
}

output "option_groups" {
  description = "Map of all option groups created"
  value       = var.context == "regional" ? module.regional[0].option_groups : null
}

output "option_groups_names" {
  description = "Map of option group names keyed by option_groups keys"
  value       = var.context == "regional" ? module.regional[0].option_groups_names : null
}

output "option_group_ids" {
  description = "Map of option group IDs"
  value       = var.context == "regional" ? module.regional[0].option_group_ids : null
}

output "option_group_arns" {
  description = "Map of option group ARNs"
  value       = var.context == "regional" ? module.regional[0].option_group_arns : null
}

output "parameter_groups" {
  description = "Map of all parameter groups created"
  value       = var.context == "regional" ? module.regional[0].parameter_groups : null
}

output "parameter_group_names" {
  description = "Map of parameter group names keyed by parameter_groups keys"
  value       = var.context == "regional" ? module.regional[0].parameter_group_names : null
}

output "parameter_group_ids" {
  description = "Map of parameter group IDs keyed by parameter_groups keys"
  value       = var.context == "regional" ? module.regional[0].parameter_group_ids : null
}

output "parameter_group_arns" {
  description = "Map of parameter group ARNs keyed by parameter_groups keys"
  value       = var.context == "regional" ? module.regional[0].parameter_group_arns : null
}

output "lambda_rds_delete_instance" {
  value = var.context == "regional" ? module.regional[0].lambda_rds_delete_instance : null
}

output "lambda_rds_modify_instance" {
  value = var.context == "regional" ? module.regional[0].lambda_rds_modify_instance : null
}

output "lambda_rds_create_snapshot" {
  value = var.context == "regional" ? module.regional[0].lambda_rds_create_snapshot : null
}

output "lambda_rds_delete_snapshot" {
  value = var.context == "regional" ? module.regional[0].lambda_rds_delete_snapshot : null
}

output "lambda_rds_restore_snapshot" {
  value = var.context == "regional" ? module.regional[0].lambda_rds_restore_snapshot : null
}

output "lambda_rds_start_stop_instance" {
  value = var.context == "regional" ? module.regional[0].lambda_rds_start_stop_instance : null
}

output "lambda_rds_status_check" {
  value = var.context == "regional" ? module.regional[0].lambda_rds_status_check : null
}

output "lambda_rds_modify_instance_version_update" {
  value = var.context == "regional" ? module.regional[0].lambda_rds_modify_instance_version_update : null
}

output "layer_request" {
  value = var.context == "regional" ? module.regional[0].layer_request : null
}

output "layer_tabulate" {
  value = var.context == "regional" ? module.regional[0].layer_tabulate : null
}

output "layer_valkey_client" {
  value = var.context == "regional" ? module.regional[0].layer_valkey_client : null
}

output "layer_oracledb" {
  value = var.context == "regional" ? module.regional[0].layer_oracledb : null
}

output "layer_mysqldb" {
  value = var.context == "regional" ? module.regional[0].layer_mysqldb : null
}

output "layer_cryptography" {
  value = var.context == "regional" ? module.regional[0].layer_cryptography : null
}

output "vpc_id" {
  description = "VPC ID"
  value       = var.context == "regional" ? module.regional[0].vpc_id : null
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = var.context == "regional" ? module.regional[0].vpc_cidr_block : null
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = var.context == "regional" ? module.regional[0].public_subnets : null
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = var.context == "regional" ? module.regional[0].private_subnets : null
}

output "database_subnets" {
  description = "Database subnet IDs"
  value       = var.context == "regional" ? module.regional[0].database_subnets : null
}

output "nat_public_ips" {
  description = "NAT Gateway Elastic IPs"
  value       = var.context == "regional" ? module.regional[0].nat_public_ips : null
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = var.context == "regional" ? module.regional[0].natgw_ids : null
}

output "public_route_table_ids" {
  description = "Public subnet route table IDs"
  value       = var.context == "regional" ? module.regional[0].public_route_table_ids : null
}

output "private_route_table_ids" {
  description = "Private subnet route table IDs"
  value       = var.context == "regional" ? module.regional[0].private_route_table_ids : null
}

output "database_route_table_ids" {
  description = "Database subnet route table IDs"
  value       = var.context == "regional" ? module.regional[0].database_route_table_ids : null
}

output "vpc_endpoints" {
  description = "VPC endpoints created"
  value       = var.context == "regional" ? module.regional[0].vpc_endpoints : null
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = var.context == "regional" ? module.regional[0].igw_id : null
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway"
  value       = var.context == "regional" ? module.regional[0].igw_arn : null
}

output "default_security_group_id" {
  value = var.context == "regional" ? module.regional[0].default_security_group_id : null
}

output "aws_service_base_security_group" {
  description = "AWS service base security group"
  value       = var.context == "regional" ? module.regional[0].aws_service_base_security_group : null
}

output "aws_database_security_group" {
  description = "AWS database security group"
  value       = var.context == "regional" ? module.regional[0].aws_database_security_group : null
}

output "db_private_subnet_group" {
  value = var.context == "regional" ? module.regional[0].db_private_subnet_group : null
}

output "db_public_subnet_group" {
  value = var.context == "regional" ? module.regional[0].db_public_subnet_group : null
}

# VPC Dependencies outputs

output "security_groups" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].security_groups : null
}

output "lambda_rds_oracle_execute_sql_statements" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].lambda_rds_oracle_execute_sql_statements : null
}

output "lambda_rds_oracle_update_users_credentials" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].lambda_rds_oracle_update_users_credentials : null
}

output "lambda_valkey_clear_cache" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].lambda_valkey_clear_cache : null
}

output "lambda_secretsmanager_rds_oracle_password_rotation" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].lambda_secretsmanager_rds_oracle_password_rotation : null
}

output "lambda_secretsmanager_rds_mysql_password_rotation" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].lambda_secretsmanager_rds_mysql_password_rotation : null
}

output "step_functions" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].step_functions : null
}

output "elasticache_valkey" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].elasticache_valkey : null
}

output "elasticache_valkey_all" {
  description = "All Valkey module instances (keyed by valkeys map key)"
  value       = var.context == "vpc-scoped" ? module.vpc_scoped[0].elasticache_valkey_all : null
}

# ECS Cluster outputs

output "ecs_cluster_arn" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].ecs_cluster_arn : null
}

output "ecs_cluster_id" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].ecs_cluster_id : null
}

output "ecs_cluster_name" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].ecs_cluster_name : null
}

output "ecs_cluster_security_group_id" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].ecs_cluster_security_group_id : null
}

output "ecs_cluster_cloud_map_namespace_id" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].ecs_cluster_cloud_map_namespace_id : null
}

output "ecs_cluster_cloud_map_namespace_arn" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].ecs_cluster_cloud_map_namespace_arn : null
}

output "ecs_cluster_cloud_map_namespace_name" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].ecs_cluster_cloud_map_namespace_name : null
}

# Load Balancer (ALB) outputs

output "albs" {
  description = "Application Load Balancer attributes keyed by schema (public/private)."
  value       = var.context == "vpc-scoped" ? module.vpc_scoped[0].albs : null
}

output "alb" {
  description = "Primary Application Load Balancer attributes. Returns the private ALB when both schemas are created."
  value       = var.context == "vpc-scoped" ? module.vpc_scoped[0].alb : null
}

output "alb_arn" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].alb_arn : null
}

output "alb_dns_name" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].alb_dns_name : null
}

output "alb_zone_id" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].alb_zone_id : null
}

output "alb_security_group_id" {
  value = var.context == "vpc-scoped" ? module.vpc_scoped[0].alb_security_group_id : null
}

output "alb_listener_arn" {
  description = "Map of listener ARNs keyed by schema and listener name. Example: alb_listener_arn[\"public\"][\"https\"]"
  value       = var.context == "vpc-scoped" ? module.vpc_scoped[0].alb_listener_arn : null
}

output "alb_primary_listener_arn" {
  description = "Listener ARNs of the primary ALB (internal if exists, otherwise public). Example: alb_primary_listener_arn[\"https\"]"
  value       = var.context == "vpc-scoped" ? module.vpc_scoped[0].alb_primary_listener_arn : null
}

output "alb_primary_security_group_id" {
  description = "Security group ID of the primary ALB (private if exists, otherwise public)."
  value       = var.context == "vpc-scoped" ? module.vpc_scoped[0].alb_primary_security_group_id : null
}

# SSM Jumpbox outputs

output "ssm_jumpbox_launch_template_id" {
  description = "SSM jumpbox launch template ID"
  value       = var.context == "regional" ? module.regional[0].ssm_jumpbox_launch_template_id : null
}

output "ssm_jumpbox_autoscaling_group_name" {
  description = "SSM jumpbox autoscaling group name"
  value       = var.context == "regional" ? module.regional[0].ssm_jumpbox_autoscaling_group_name : null
}

output "ssm_jumpbox_security_group" {
  description = "SSM jumpbox security group"
  value       = var.context == "regional" ? module.regional[0].ssm_jumpbox_security_group : null
}