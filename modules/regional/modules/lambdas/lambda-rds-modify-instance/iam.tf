module "iam_role_lambda_rds_modify_instance" {
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
    RdsModifyDeny = {
      sid       = "RdsModifyDenyPolicy"
      effect    = "Deny"
      actions   = ["rds:ModifyDBInstance"]
      resources = ["arn:aws:rds:*:${var.aws_account_id}:db:*-dbprod"]
    }

    RdsModifyAllow = {
      sid    = "RdsModifyAllowPolicy"
      effect = "Allow"
      actions = [
        "rds:AddRoleToDBInstance",
        "rds:DescribeDBInstances",
        "rds:ModifyDBInstance",
        "rds:RemoveRoleFromDBInstance"
      ]
      resources = ["arn:aws:rds:*:${var.aws_account_id}:db:*"]
    }

    IamPassRole = {
      sid     = "IamPassRolePolicy"
      effect  = "Allow"
      actions = ["iam:PassRole"]
      resources = [
        var.iam_role_rds_enhanced_monitoring_arn,
        var.iam_role_rds_s3_integration_arn
      ]
    }

    SecretsManager = {
      sid       = "SecretsManagerPolicy"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["arn:aws:secretsmanager:*:${var.aws_account_id}:secret:*"]
    }

    Kms = {
      sid    = "KmsPolicy"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:CreateGrant"
      ]
      resources = ["arn:aws:kms:*:${var.aws_account_id}:alias/aws/lambda"]
    }
  }

  policies = {
    AWSLambdaBasicExecutionRole = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  }
}