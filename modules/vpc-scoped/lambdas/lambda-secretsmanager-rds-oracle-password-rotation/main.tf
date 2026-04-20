############################################################
# Lambda Secretsmanager RDS Oracle Password Rotation      🇧🇷
############################################################

data "archive_file" "lambda_secretsmanager_rds_oracle_password_rotation" {
  type        = "zip"
  source_file = "${path.module}/files/lambda_function.py"
  output_path = "${path.module}/files/lambda_function.zip"
}

locals {
  lambda_function_name                      = "${var.resource_prefix}-secretsmanager-rds-oracle-password-rotation"
  lambda_function_iam_role_name             = "lambda-${local.lambda_function_name}"
  create_lambda_function_effective          = var.create == null ? var.create_lambda_function : var.create
  create_lambda_function_iam_role_effective = var.create == null ? var.create_lambda_function_iam_role : var.create
}

module "lambda_secretsmanager_rds_oracle_password_rotation" {
  source                                  = "terraform-aws-modules/lambda/aws"
  version                                 = "~> 8.0"
  function_name                           = local.lambda_function_name
  description                             = "Rotates a Secrets Manager secret for Amazon RDS oracle credentials using the single user rotation strategy."
  handler                                 = "lambda_function.lambda_handler"
  runtime                                 = "python3.13"
  timeout                                 = 300
  create_function                         = local.create_lambda_function_effective
  create_role                             = false
  lambda_role                             = module.iam_role_lambda_secretsmanager_rds_oracle_password_rotation.arn
  create_package                          = false
  create_current_version_allowed_triggers = false
  local_existing_package                  = data.archive_file.lambda_secretsmanager_rds_oracle_password_rotation.output_path
  ignore_source_code_hash                 = true
  layers                                  = var.lambda_layers
  vpc_subnet_ids                          = var.subnet_ids
  vpc_security_group_ids                  = var.vpc_security_group_ids
  environment_variables = {
    SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.aws_region}.amazonaws.com"
    EXCLUDE_PUNCTUATION      = "True"
  }
  allowed_triggers = {
    AllowInvokeLambdaFromSM = {
      principal    = "secretsmanager.amazonaws.com"
      action       = "lambda:InvokeFunction"
      statement_id = "AllowInvokeLambdaFromSM"
    }
  }

  tags = {
    Name = local.lambda_function_name
  }
}