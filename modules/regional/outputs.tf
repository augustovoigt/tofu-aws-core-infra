# AWS S3 Buckets - Outputs

output "s3_buckets" {
  description = "Map of S3 buckets created"
  value       = module.s3_bucket
}

output "s3_bucket_ids" {
  description = "Map of S3 bucket IDs"
  value       = { for k, v in module.s3_bucket : k => v.s3_bucket_id }
}

output "s3_bucket_arns" {
  description = "Map of S3 bucket ARNs"
  value       = { for k, v in module.s3_bucket : k => v.s3_bucket_arn }
}

# AWS RDS Option Groups - Outputs

output "option_groups" {
  description = "Map of all option groups created"
  value       = module.option_group
}

output "option_groups_names" {
  description = "Map of option group names keyed by option_groups keys"
  value       = { for k, v in module.option_group : k => local.rds_option_groups[k].name }
}

output "option_group_ids" {
  description = "Map of option group IDs"
  value       = { for k, v in module.option_group : k => v.db_option_group_id }
}

output "option_group_arns" {
  description = "Map of option group ARNs"
  value       = { for k, v in module.option_group : k => v.db_option_group_arn }
}

# AWS RDS Parameter Groups - Outputs

output "parameter_groups" {
  description = "Map of all parameter groups created"
  value       = module.parameter_group
}

output "parameter_group_names" {
  description = "Map of parameter group names keyed by parameter_groups keys"
  value       = { for k, v in module.parameter_group : k => local.rds_parameter_groups[k].name }
}

output "parameter_group_ids" {
  description = "Map of parameter group IDs keyed by parameter_groups keys"
  value       = { for k, v in module.parameter_group : k => v.db_parameter_group_id }
}

output "parameter_group_arns" {
  description = "Map of parameter group ARNs keyed by parameter_groups keys"
  value       = { for k, v in module.parameter_group : k => v.db_parameter_group_arn }
}

# AWS Lambdas - Outputs

output "lambda_rds_delete_instance" {
  value = module.lambda_rds_delete_instance
}

output "lambda_rds_modify_instance" {
  value = module.lambda_rds_modify_instance
}

output "lambda_rds_create_snapshot" {
  value = module.lambda_rds_create_snapshot
}

output "lambda_rds_delete_snapshot" {
  value = module.lambda_rds_delete_snapshot
}

output "lambda_rds_restore_snapshot" {
  value = module.lambda_rds_restore_snapshot
}

output "lambda_rds_start_stop_instance" {
  value = module.lambda_rds_start_stop_instance
}

output "lambda_rds_status_check" {
  value = module.lambda_rds_status_check
}

output "lambda_rds_modify_instance_version_update" {
  value = module.lambda_rds_modify_instance_version_update
}

# AWS Lambdas Layers - Outputs

output "layer_request" {
  value = module.layer_request
}

output "layer_tabulate" {
  value = module.layer_tabulate
}

output "layer_valkey_client" {
  value = module.layer_valkey_client
}

output "layer_oracledb" {
  value = module.layer_oracledb
}

output "layer_mysqldb" {
  value = module.layer_mysqldb
}

output "layer_cryptography" {
  value = module.layer_cryptography
}

# VPC - Outputs

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnets
}

output "nat_public_ips" {
  description = "NAT Gateway Elastic IPs"
  value       = module.vpc.nat_public_ips
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "public_route_table_ids" {
  description = "Public subnet route table IDs"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "Private subnet route table IDs"
  value       = module.vpc.private_route_table_ids
}

output "database_route_table_ids" {
  description = "Database subnet route table IDs"
  value       = module.vpc.database_route_table_ids
}

output "vpc_endpoints" {
  description = "VPC endpoints created."
  value       = var.create_vpc ? module.vpc_gateway_endpoints[0].endpoints : {}
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway"
  value       = module.vpc.igw_arn
}

output "default_security_group_id" {
  value = module.vpc.default_security_group_id
}

output "aws_service_base_security_group" {
  description = "AWS service base security group"
  value       = var.create_vpc ? module.vpc-services[0].aws_service_base_security_group : null
}

output "aws_database_security_group" {
  description = "AWS database security group"
  value       = var.create_vpc ? module.vpc-services[0].aws_database_security_group : null
}

output "db_private_subnet_group" {
  value = var.create_vpc ? module.vpc-services[0].db_private_subnet_group : null
}

output "db_public_subnet_group" {
  value = var.create_vpc ? module.vpc-services[0].db_public_subnet_group : null
}

# SSM Jumpbox - Outputs

output "ssm_jumpbox_launch_template_id" {
  description = "SSM jumpbox launch template ID"
  value       = module.ssm_jumpbox.launch_template_id
}

output "ssm_jumpbox_autoscaling_group_name" {
  description = "SSM jumpbox autoscaling group name"
  value       = module.ssm_jumpbox.autoscaling_group_name
}

output "ssm_jumpbox_security_group" {
  description = "SSM jumpbox security group"
  value       = module.ssm_jumpbox.security_group
}