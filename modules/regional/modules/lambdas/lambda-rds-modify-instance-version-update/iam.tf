module "iam_role_lambda_rds_modify_instance_version_update" {
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
    RdsModifyVersionUpdate = {
      sid    = "RdsModifyVersionUpdatePolicy"
      effect = "Allow"
      actions = [
        "rds:DescribeDBInstances",
        "rds:ModifyDBInstance",
        "rds:DescribeDBParameterGroups",
        "rds:AddRoleToDBInstance",
        "rds:RemoveRoleFromDBInstance",
        "rds:RebootDBInstance"
      ]
      resources = [
        "arn:aws:rds:*:${var.aws_account_id}:db:*",
        "arn:aws:rds:*:${var.aws_account_id}:pg:*"
      ]
    }

    SsmAccess = {
      sid       = "SsmAccessPolicy"
      effect    = "Allow"
      actions   = ["ssm:GetParameter*"]
      resources = ["arn:aws:ssm:*:${var.aws_account_id}:parameter/*"]
    }
  }

  policies = {
    AWSLambdaBasicExecutionRole = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  }
}