data "archive_file" "lambda_rds_status_check" {
  type        = "zip"
  source_file = "${path.module}/files/lambda_function.py"
  output_path = "${path.module}/files/lambda_function.zip"
}

locals {
  lambda_function_name                      = "rds-status-check"
  lambda_function_iam_role_name             = "lambda-${local.lambda_function_name}-${var.aws_region}"
  create_lambda_function_effective          = var.create == null ? var.create_lambda_function : var.create
  create_lambda_function_iam_role_effective = var.create == null ? var.create_lambda_function_iam_role : var.create
}

module "lambda_rds_status_check" {
  source                  = "terraform-aws-modules/lambda/aws"
  version                 = "~> 8.0"
  function_name           = local.lambda_function_name
  description             = "Check RDS instance status (used by step-functions)."
  handler                 = "lambda_function.lambda_handler"
  runtime                 = "python3.13"
  timeout                 = 300
  create_function         = local.create_lambda_function_effective
  create_role             = false
  lambda_role             = module.iam_role_lambda_rds_status_check.arn
  create_package          = false
  local_existing_package  = data.archive_file.lambda_rds_status_check.output_path
  ignore_source_code_hash = true
  tags = {
    Name = local.lambda_function_name
  }
}