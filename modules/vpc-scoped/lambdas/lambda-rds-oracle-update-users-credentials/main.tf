############################################################
# Lambda RDS Oracle Update Users Credentials              🇧🇷
############################################################

data "archive_file" "lambda_rds_oracle_update_users_credentials" {
  type        = "zip"
  source_file = "${path.module}/files/lambda_function.py"
  output_path = "${path.module}/files/lambda_function.zip"
}

locals {
  lambda_function_name                      = "${var.resource_prefix}-rds-oracle-update-users-credentials"
  lambda_function_iam_role_name             = "lambda-${local.lambda_function_name}"
  create_lambda_function_effective          = var.create == null ? var.create_lambda_function : var.create
  create_lambda_function_iam_role_effective = var.create == null ? var.create_lambda_function_iam_role : var.create
}

module "lambda_rds_oracle_update_users_credentials" {
  source                  = "terraform-aws-modules/lambda/aws"
  version                 = "~> 8.0"
  function_name           = local.lambda_function_name
  description             = "Manages RDS Oracle users by ensuring they exist, updating passwords, and granting necessary privileges."
  handler                 = "lambda_function.lambda_handler"
  runtime                 = "python3.13"
  timeout                 = 90
  create_function         = local.create_lambda_function_effective
  create_role             = false
  lambda_role             = module.iam_role_lambda_rds_oracle_update_users_credentials.arn
  create_package          = false
  local_existing_package  = data.archive_file.lambda_rds_oracle_update_users_credentials.output_path
  ignore_source_code_hash = true
  layers                  = var.lambda_layers
  vpc_subnet_ids          = var.subnet_ids
  vpc_security_group_ids  = var.vpc_security_group_ids

  tags = {
    Name = local.lambda_function_name
  }
}