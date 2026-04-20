module "iam_role_lambda_rds_delete_instance" {
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
    DenyProdDelete = {
      sid    = "DenyProdDeletePolicy"
      effect = "Deny"
      actions = [
        "rds:DeleteDBInstance"
      ]
      resources = ["arn:aws:rds:*:${var.aws_account_id}:db:*-dbprod"]
    }

    AllowRdsDelete = {
      sid    = "AllowRdsDeletePolicy"
      effect = "Allow"
      actions = [
        "rds:AddTagsToResource",
        "rds:CreateDBSnapshot", # used by final snapshot
        "rds:DeleteDBInstance",
        "rds:DescribeDBInstances"
      ]
      resources = [
        "arn:aws:rds:*:${var.aws_account_id}:db:*",
        "arn:aws:rds:*:${var.aws_account_id}:snapshot:*"
      ]
    }

    LambdaKmsAccess = {
      sid    = "LambdaKmsAccessPolicy"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:CreateGrant"
      ]
      resources = ["arn:aws:kms:*:${var.aws_account_id}:alias/aws/lambda"]
    }

    LambdaLogs = {
      sid    = "LambdaLogsPolicy"
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = ["*"]
    }
  }

  policies = {
    AWSLambdaBasicExecutionRole = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  }
}