############################################################
# Lambda RDS Delete Snapshot                              🇧🇷
############################################################

data "archive_file" "lambda_rds_delete_snapshot" {
  type        = "zip"
  source_file = "${path.module}/files/lambda_function.py"
  output_path = "${path.module}/files/lambda_function.zip"
}

locals {
  lambda_function_name                      = "rds-delete-snapshot"
  lambda_function_iam_role_name             = "lambda-${local.lambda_function_name}-${var.aws_region}"
  create_lambda_function_effective          = var.create == null ? var.create_lambda_function : var.create
  create_lambda_function_iam_role_effective = var.create == null ? var.create_lambda_function_iam_role : var.create
}

module "lambda_rds_delete_snapshot" {
  source                  = "terraform-aws-modules/lambda/aws"
  version                 = "~> 8.0"
  function_name           = local.lambda_function_name
  description             = "Deletes existing RDS snapshots, handles errors, and tracks successful deletions."
  handler                 = "lambda_function.lambda_handler"
  runtime                 = "python3.13"
  timeout                 = 300
  create_role             = false
  create_function         = local.create_lambda_function_effective
  lambda_role             = module.iam_role_lambda_rds_delete_snapshot.arn
  create_package          = false
  local_existing_package  = data.archive_file.lambda_rds_delete_snapshot.output_path
  ignore_source_code_hash = true
  tags = {
    Name = local.lambda_function_name
  }
}