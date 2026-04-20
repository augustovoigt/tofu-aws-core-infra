module "iam_role_lambda_rds_restore_snapshot" {
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
    DenyRestoreOnProd = {
      sid       = "DenyRestoreOnProdPolicy"
      effect    = "Deny"
      actions   = ["rds:RestoreDBInstanceFromDBSnapshot"]
      resources = ["arn:aws:rds:*:${var.aws_account_id}:db:*-dbprod"]
    }

    RestoreSnapshotAccess = {
      sid    = "RestoreSnapshotAccessPolicy"
      effect = "Allow"
      actions = [
        "rds:DescribeDBInstances",
        "rds:DescribeDBSnapshots",
        "rds:RestoreDBInstanceFromDBSnapshot",
        "rds:AddTagsToResource"
      ]
      resources = [
        "arn:aws:rds:*:${var.aws_account_id}:db:*",
        "arn:aws:rds:*:${var.aws_account_id}:snapshot:*",
        "arn:aws:rds:*:${var.aws_account_id}:og:*",
        "arn:aws:rds:*:${var.aws_account_id}:pg:*",
        "arn:aws:rds:*:${var.aws_account_id}:subgrp:*"
      ]
    }

    KMSAccess = {
      sid     = "KMSAccessPolicy"
      effect  = "Allow"
      actions = ["kms:Encrypt", "kms:Decrypt", "kms:DescribeKey", "kms:CreateGrant"]
      resources = [
        "arn:aws:kms:*:${var.aws_account_id}:alias/aws/lambda",
        "arn:aws:kms:*:987654321098:key/*"
      ]
    }
  }

  policies = {
    AWSLambdaBasicExecutionRole = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  }
}