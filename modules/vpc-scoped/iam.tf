locals {
  iam_roles_default = {
    cloudwatch_exporter = {
      create = var.create_iam_role_cloudwatch_exporter
      name   = "${var.resource_prefix}-cloudwatch-exporter-role"

      trust_policy_permissions = var.eks_oidc_provider_arn != null && var.eks_oidc_provider_arn != "" ? {
        oidc_trust = {
          sid     = "OIDCTrust"
          effect  = "Allow"
          actions = ["sts:TagSession", "sts:AssumeRoleWithWebIdentity"]
          principals = [
            {
              type        = "Federated"
              identifiers = [var.eks_oidc_provider_arn]
            }
          ]
        }
      } : {}

      create_inline_policy = true
      inline_policy_permissions = {
        cloudwatch_exporter = {
          sid    = "CloudWatchExporter"
          effect = "Allow"
          actions = [
            "tag:GetResources",
            "cloudwatch:GetMetricData",
            "cloudwatch:GetMetricStatistics",
            "cloudwatch:ListMetrics",
            "apigateway:GET",
            "aps:ListWorkspaces",
            "autoscaling:DescribeAutoScalingGroups",
            "dms:DescribeReplicationInstances",
            "dms:DescribeReplicationTasks",
            "ec2:DescribeTransitGatewayAttachments",
            "ec2:DescribeSpotFleetRequests",
            "shield:ListProtections",
            "storagegateway:ListGateways",
            "storagegateway:ListTagsForResource",
            "iam:ListAccountAliases"
          ]
          resources = ["*"]
        }
      }
      policies = {}
    }

    prometheus_rds_exporter = {
      create = var.create_iam_role_prometheus_rds_exporter
      name   = "${var.resource_prefix}-prometheus-rds-exporter-role"

      trust_policy_permissions = var.eks_oidc_provider_arn != null && var.eks_oidc_provider_arn != "" ? {
        oidc_trust = {
          sid     = "OIDCTrust"
          effect  = "Allow"
          actions = ["sts:TagSession", "sts:AssumeRoleWithWebIdentity"]
          principals = [
            {
              type        = "Federated"
              identifiers = [var.eks_oidc_provider_arn]
            }
          ]
        }
      } : {}

      create_inline_policy = true
      inline_policy_permissions = {
        allow_instance_and_log_descriptions = {
          sid       = "RDSInstanceAndLogDescriptions"
          effect    = "Allow"
          actions   = ["rds:DescribeDBInstances", "rds:DescribeDBLogFiles"]
          resources = ["arn:aws:rds:*:*:db:*"]
        }
        allow_maintenance_descriptions = {
          sid       = "RDSMaintenanceDescriptions"
          effect    = "Allow"
          actions   = ["rds:DescribePendingMaintenanceActions"]
          resources = ["*"]
        }
        allow_getting_cloudwatch_metrics = {
          sid       = "CloudWatchGetMetrics"
          effect    = "Allow"
          actions   = ["cloudwatch:GetMetricData"]
          resources = ["*"]
        }
        allow_rds_usage_descriptions = {
          sid       = "RDSUsageDescriptions"
          effect    = "Allow"
          actions   = ["rds:DescribeAccountAttributes"]
          resources = ["*"]
        }
        allow_quota_descriptions = {
          sid       = "ServiceQuotaDescriptions"
          effect    = "Allow"
          actions   = ["servicequotas:GetServiceQuota"]
          resources = ["*"]
        }
        allow_instance_type_descriptions = {
          sid       = "EC2InstanceTypeDescriptions"
          effect    = "Allow"
          actions   = ["ec2:DescribeInstanceTypes"]
          resources = ["*"]
        }
      }
      policies = {}
    }

    finops_cronjob = {
      create = var.create_iam_role_finops_cronjob
      name   = "${var.resource_prefix}-finops-cronjob-role"

      trust_policy_permissions = var.eks_oidc_provider_arn != null && var.eks_oidc_provider_arn != "" ? {
        oidc_trust = {
          sid     = "OIDCTrust"
          effect  = "Allow"
          actions = ["sts:TagSession", "sts:AssumeRoleWithWebIdentity"]
          principals = [
            {
              type        = "Federated"
              identifiers = [var.eks_oidc_provider_arn]
            }
          ]
        }
      } : {}

      create_inline_policy = true
      inline_policy_permissions = {
        s3_access = {
          sid     = "S3Access"
          effect  = "Allow"
          actions = ["s3:PutObject", "s3:ListBucket"]
          resources = [
            "arn:aws:s3:::finops-metrics",
            "arn:aws:s3:::finops-metrics/*"
          ]
        }
      }
      policies = {}
    }

    step_functions_dump_rds = {
      create = var.create_iam_role_step_functions_dump_rds
      name   = "${var.resource_prefix}-step-functions-dump-rds-role"

      trust_policy_permissions = {
        assume_role_by_stepfunctions = {
          sid     = "StepFunctionsTrust"
          effect  = "Allow"
          actions = ["sts:AssumeRole"]
          principals = [
            {
              type        = "Service"
              identifiers = ["states.amazonaws.com"]
            }
          ]
        }
      }

      policies = {
        lambda_role = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
      }

      create_inline_policy = true
      inline_policy_permissions = {
        stepfunctions_invoke_lambda = {
          sid       = "StepFunctionsInvokeLambda"
          effect    = "Allow"
          actions   = ["lambda:InvokeFunction"]
          resources = ["*"]
        }
      }
    }

    step_functions_version_update = {
      create = var.create_iam_role_step_functions_version_update
      name   = "${var.resource_prefix}-step-functions-version-update-role"

      trust_policy_permissions = {
        assume_role_by_stepfunctions = {
          sid     = "StepFunctionsTrust"
          effect  = "Allow"
          actions = ["sts:AssumeRole"]
          principals = [
            {
              type        = "Service"
              identifiers = ["states.amazonaws.com"]
            }
          ]
        }
      }

      policies = {
        lambda_role = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
      }

      create_inline_policy = true
      inline_policy_permissions = {
        stepfunctions_invoke_lambda = {
          sid       = "StepFunctionsInvokeLambda"
          effect    = "Allow"
          actions   = ["lambda:InvokeFunction"]
          resources = ["*"]
        }
      }
    }
  }

  iam_roles = merge(local.iam_roles_default, var.iam_roles)
}

module "iam_roles" {
  source   = "terraform-aws-modules/iam/aws//modules/iam-role"
  version  = "6.4.0"
  for_each = { for k, v in local.iam_roles : k => v if try(v.create, true) }

  name                      = each.value.name
  use_name_prefix           = false
  trust_policy_permissions  = each.value.trust_policy_permissions
  create_inline_policy      = each.value.create_inline_policy
  inline_policy_permissions = each.value.inline_policy_permissions
  policies                  = each.value.policies
}