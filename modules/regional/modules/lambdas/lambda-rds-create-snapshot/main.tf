############################################################
# Lambda RDS Create Snapshot                              🇧🇷
############################################################

data "archive_file" "lambda_rds_create_snapshot" {
  type        = "zip"
  source_file = "${path.module}/files/lambda_function.py"
  output_path = "${path.module}/files/lambda_function.zip"
}

locals {
  lambda_function_name                      = "rds-create-snapshot"
  lambda_function_iam_role_name             = "lambda-${local.lambda_function_name}-${var.aws_region}"
  create_lambda_function_effective          = var.create == null ? var.create_lambda_function : var.create
  create_lambda_function_iam_role_effective = var.create == null ? var.create_lambda_function_iam_role : var.create
}

module "lambda_rds_create_snapshot" {
  source                  = "terraform-aws-modules/lambda/aws"
  version                 = "~> 8.0"
  function_name           = local.lambda_function_name
  description             = "Creates an RDS snapshot, tracks status with Step Functions, and retries until completion or timeout."
  handler                 = "lambda_function.lambda_handler"
  runtime                 = "python3.13"
  timeout                 = 300
  create_function         = local.create_lambda_function_effective
  create_role             = false
  lambda_role             = module.iam_role_lambda_rds_create_snapshot.arn
  create_package          = false
  local_existing_package  = data.archive_file.lambda_rds_create_snapshot.output_path
  ignore_source_code_hash = true
  tags = {
    Name = local.lambda_function_name
  }
}