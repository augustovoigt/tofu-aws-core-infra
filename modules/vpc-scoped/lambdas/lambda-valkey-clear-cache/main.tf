data "archive_file" "lambda_valkey_clear_cache" {
  type        = "zip"
  source_file = "${path.module}/files/lambda_function.py"
  output_path = "${path.module}/files/lambda_function.zip"
}

locals {
  lambda_function_name                      = "${var.resource_prefix}-valkey-clear-cache"
  lambda_function_iam_role_name             = "lambda-${local.lambda_function_name}"
  create_lambda_function_effective          = var.create == null ? var.create_lambda_function : var.create
  create_lambda_function_iam_role_effective = var.create == null ? var.create_lambda_function_iam_role : var.create
}

module "lambda_valkey_clear_cache" {
  source                  = "terraform-aws-modules/lambda/aws"
  version                 = "~> 8.0"
  function_name           = local.lambda_function_name
  description             = "Delete ValKey keys with a specific prefix."
  handler                 = "lambda_function.lambda_handler"
  runtime                 = "python3.13"
  timeout                 = 90
  create_function         = local.create_lambda_function_effective
  create_role             = false
  lambda_role             = module.iam_role_lambda_valkey_clear_cache.arn
  create_package          = false
  local_existing_package  = data.archive_file.lambda_valkey_clear_cache.output_path
  ignore_source_code_hash = true
  layers                  = var.lambda_layers
  vpc_subnet_ids          = var.subnet_ids
  vpc_security_group_ids  = var.vpc_security_group_ids

  tags = {
    Name = local.lambda_function_name
  }
}