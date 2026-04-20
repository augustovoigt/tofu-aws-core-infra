data "aws_caller_identity" "current" {}

# Create iam role definitions

locals {
  iam_default_roles = {
    eventbridge_scheduler = {
      create = var.create_iam_role_eventbridge_scheduler
      name   = "platform-ops-eventbridge-scheduler-role"
      trust_policy_permissions = {
        Scheduler = {
          sid     = "SchedulerTrust"
          effect  = "Allow"
          actions = ["sts:AssumeRole"]
          principals = [
            {
              type        = "Service"
              identifiers = ["scheduler.amazonaws.com"]
            }
          ]
        }
      }
      create_inline_policy = true
      inline_policy_permissions = {
        EventBridgeSchedulerAccess = {
          sid       = "EventBridgeSchedulerAccess"
          effect    = "Allow"
          actions   = ["lambda:InvokeFunction", "states:StartExecution"]
          resources = ["*"]
        }
      }
      policies = {}
    }

    rds_enhanced_monitoring = {
      create = var.create_iam_role_rds_enhanced_monitoring
      name   = "platform-ops-rds-enhanced-monitoring-role"
      trust_policy_permissions = {
        RdsMonitoring = {
          sid     = "RdsMonitoringTrust"
          effect  = "Allow"
          actions = ["sts:AssumeRole"]
          principals = [
            {
              type        = "Service"
              identifiers = ["monitoring.rds.amazonaws.com"]
            }
          ]
        }
      }
      create_inline_policy      = false
      inline_policy_permissions = {}
      policies = {
        AmazonRDSEnhancedMonitoringRole = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
      }
    }

    rds_s3_integration = {
      create = var.create_iam_role_rds_s3_integration
      name   = "platform-ops-rds-s3-integration-role"
      trust_policy_permissions = {
        RdsIntegration = {
          sid     = "RdsIntegrationTrust"
          effect  = "Allow"
          actions = ["sts:AssumeRole"]
          principals = [
            {
              type        = "Service"
              identifiers = ["rds.amazonaws.com"]
            }
          ]
        }
      }
      create_inline_policy = true
      inline_policy_permissions = {
        RdsS3IntegrationAccess = {
          sid     = "RdsS3IntegrationAccess"
          effect  = "Allow"
          actions = ["s3:GetObject", "s3:ListBucket", "s3:PutObject"]
          resources = [
            "arn:aws:s3:::central-backups-987654321098-*",
            "arn:aws:s3:::central-backups-987654321098-*/*",
            "arn:aws:s3:::platform-temp-${data.aws_caller_identity.current.account_id}-*",
            "arn:aws:s3:::platform-temp-${data.aws_caller_identity.current.account_id}-*/*",
            "arn:aws:s3:::finops-metrics",
            "arn:aws:s3:::finops-metrics/*"
          ]
        }
      }
      policies = {}
    }

    cross_account_finops = {
      create = var.create_iam_role_cross_account_finops
      name   = "CrossAccount-FinOps"
      trust_policy_permissions = {
        FinOpsCrossAccount = {
          sid     = "FinOpsCrossAccountTrust"
          effect  = "Allow"
          actions = ["sts:AssumeRole"]
          principals = [
            {
              type        = "AWS"
              identifiers = ["arn:aws:iam::111122223333:root"]
            }
          ]
        }
      }
      create_inline_policy      = false
      inline_policy_permissions = {}
      policies = {
        ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess"
      }
    }
  }

  iam_roles = merge(local.iam_default_roles, var.iam_roles)
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