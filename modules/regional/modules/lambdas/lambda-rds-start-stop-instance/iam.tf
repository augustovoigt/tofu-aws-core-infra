module "iam_role_lambda_rds_start_stop_instance" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.4.0"

  create          = local.create_lambda_function_iam_role_effective
  name            = local.lambda_function_iam_role_name
  use_name_prefix = false

  trust_policy_permissions = {
    Lambda = {
      sid     = "LambdaTrustPolicy"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["lambda.amazonaws.com"]
      }]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    RDSStartStopAccess = {
      sid       = "RDSStartStopAccessPolicy"
      effect    = "Allow"
      actions   = ["rds:DescribeDBInstances", "rds:StopDBInstance", "rds:StartDBInstance"]
      resources = ["arn:aws:rds:*:${var.aws_account_id}:db:*"]
    }

    KMSAccess = {
      sid       = "KMSAccessPolicy"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:Encrypt", "kms:CreateGrant"]
      resources = ["arn:aws:kms:*:${var.aws_account_id}:alias/aws/lambda"]
    }
  }

  policies = {
    AWSLambdaBasicExecutionRole = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  }
}