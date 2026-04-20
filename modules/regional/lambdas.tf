# AWS Lambdas

module "lambda_rds_delete_instance" {
  source         = "./modules/lambdas/lambda-rds-delete-instance"
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
  create         = var.create_lambda_rds_delete_instance
}

module "lambda_rds_modify_instance" {
  source                               = "./modules/lambdas/lambda-rds-modify-instance"
  aws_account_id                       = var.aws_account_id
  aws_region                           = var.aws_region
  create                               = var.create_lambda_rds_modify_instance
  iam_role_rds_enhanced_monitoring_arn = var.iam_role_rds_enhanced_monitoring_arn
  iam_role_rds_s3_integration_arn      = var.iam_role_rds_s3_integration_arn
}

module "lambda_rds_create_snapshot" {
  source         = "./modules/lambdas/lambda-rds-create-snapshot"
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
  create         = var.create_lambda_rds_create_snapshot
}

module "lambda_rds_delete_snapshot" {
  source         = "./modules/lambdas/lambda-rds-delete-snapshot"
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
  create         = var.create_lambda_rds_delete_snapshot
}

module "lambda_rds_restore_snapshot" {
  source         = "./modules/lambdas/lambda-rds-restore-snapshot"
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
  create         = var.create_lambda_rds_restore_snapshot
}

module "lambda_rds_start_stop_instance" {
  source         = "./modules/lambdas/lambda-rds-start-stop-instance"
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
  create         = var.create_lambda_rds_start_stop_instance
}

module "lambda_rds_status_check" {
  source         = "./modules/lambdas/lambda-rds-status-check"
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
  create         = var.create_lambda_rds_status_check
}

module "lambda_rds_modify_instance_version_update" {
  source         = "./modules/lambdas/lambda-rds-modify-instance-version-update"
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
  create         = var.create_lambda_rds_modify_instance_version_update
}

# AWS Lambdas - Layers

module "layer_request" {
  source      = "./modules/lambdas/layer-request"
  bucket_name = var.create_layer_request ? module.s3_bucket["platform_temp"].s3_bucket_id : null
  create      = var.create_layer_request
  depends_on  = [aws_s3_object.lambda_layers]
}

module "layer_tabulate" {
  source      = "./modules/lambdas/layer-tabulate"
  bucket_name = var.create_layer_tabulate ? module.s3_bucket["platform_temp"].s3_bucket_id : null
  create      = var.create_layer_tabulate
  depends_on  = [aws_s3_object.lambda_layers]
}

module "layer_valkey_client" {
  source      = "./modules/lambdas/layer-valkey-client"
  bucket_name = var.create_layer_valkey_client ? module.s3_bucket["platform_temp"].s3_bucket_id : null
  create      = var.create_layer_valkey_client
  depends_on  = [aws_s3_object.lambda_layers]
}

module "layer_oracledb" {
  source      = "./modules/lambdas/layer-oracledb"
  bucket_name = var.create_layer_oracledb ? module.s3_bucket["platform_temp"].s3_bucket_id : null
  create      = var.create_layer_oracledb
  depends_on  = [aws_s3_object.lambda_layers]
}

module "layer_mysqldb" {
  source      = "./modules/lambdas/layer-mysqldb"
  bucket_name = var.create_layer_mysqldb ? module.s3_bucket["platform_temp"].s3_bucket_id : null
  create      = var.create_layer_mysqldb
  depends_on  = [aws_s3_object.lambda_layers]
}

module "layer_cryptography" {
  source      = "./modules/lambdas/layer-cryptography"
  bucket_name = var.create_layer_cryptography ? module.s3_bucket["platform_temp"].s3_bucket_id : null
  create      = var.create_layer_cryptography
  depends_on  = [aws_s3_object.lambda_layers]
}