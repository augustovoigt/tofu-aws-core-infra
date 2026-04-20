# AWS Lambdas

module "lambda_rds_oracle_execute_sql_statements" {
  source                 = "./lambdas/lambda-rds-oracle-execute-sql-statements"
  aws_account_id         = var.aws_account_id
  resource_prefix        = var.resource_prefix
  create                 = var.create_lambda_rds_oracle_execute_sql_statements
  lambda_layers          = compact([var.lambda_layer_oracledb_arn, var.lambda_layer_tabulate_arn])
  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [var.aws_service_base_security_group_id]
}

module "lambda_rds_oracle_update_users_credentials" {
  source                 = "./lambdas/lambda-rds-oracle-update-users-credentials"
  aws_account_id         = var.aws_account_id
  resource_prefix        = var.resource_prefix
  create                 = var.create_lambda_rds_oracle_update_users_credentials
  lambda_layers          = compact([var.lambda_layer_oracledb_arn, var.lambda_layer_tabulate_arn])
  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [var.aws_service_base_security_group_id]
}

module "lambda_valkey_clear_cache" {
  source                 = "./lambdas/lambda-valkey-clear-cache"
  aws_account_id         = var.aws_account_id
  resource_prefix        = var.resource_prefix
  create                 = var.create_lambda_valkey_clear_cache
  lambda_layers          = compact([var.lambda_layer_valkey_client_arn, var.lambda_layer_request_arn])
  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [var.aws_service_base_security_group_id]
}

module "lambda_secretsmanager_rds_oracle_password_rotation" {
  source                 = "./lambdas/lambda-secretsmanager-rds-oracle-password-rotation"
  aws_account_id         = var.aws_account_id
  aws_region             = var.aws_region
  resource_prefix        = var.resource_prefix
  create                 = var.create_lambda_secretsmanager_rds_oracle_password_rotation
  lambda_layers          = compact([var.lambda_layer_oracledb_arn, var.lambda_layer_tabulate_arn])
  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [var.aws_service_base_security_group_id]
}

module "lambda_secretsmanager_rds_mysql_password_rotation" {
  source                 = "./lambdas/lambda-secretsmanager-rds-mysql-password-rotation"
  aws_account_id         = var.aws_account_id
  aws_region             = var.aws_region
  resource_prefix        = var.resource_prefix
  create                 = var.create_lambda_secretsmanager_rds_mysql_password_rotation
  lambda_layers          = compact([var.lambda_layer_mysqldb_arn, var.lambda_layer_tabulate_arn, var.lambda_layer_cryptography_arn])
  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [var.aws_service_base_security_group_id]
}