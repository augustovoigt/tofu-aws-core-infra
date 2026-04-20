module "iam_role_lambda_secretsmanager_rds_oracle_password_rotation" {
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
    EC2SecretsManagerAccess = {
      sid    = "EC2SecretsManagerAccessPolicy"
      effect = "Allow"
      actions = [
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:Describe*",
        "ec2:DetachNetworkInterface",
        "ec2:Get*",
        "ec2:List*",
        "kms:ListAliases",
        "secretsmanager:Describe*",
        "secretsmanager:Get*",
        "secretsmanager:List*",
        "secretsmanager:PutSecretValue",
        "secretsmanager:UpdateSecretVersionStage"
      ]
      resources = ["*"]
    }

    KMSAccess = {
      sid       = "KMSAccessPolicy"
      effect    = "Allow"
      actions   = ["kms:Decrypt", "kms:Encrypt", "kms:CreateGrant"]
      resources = ["arn:aws:kms:*:${var.aws_account_id}:alias/aws/lambda"]
    }
  }

  policies = {
    AWSLambdaBasicExecutionRole     = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    AWSLambdaVPCAccessExecutionRole = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  }
}