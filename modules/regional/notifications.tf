# AWS Notifications (SNS / Eventbridge)

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  sns_topic_arn = var.create_sns_topic ? module.sns_topic[0].topic_arn : var.sns_topic_arn_override

  sns_subscriptions = length(var.sns_topic_subscriptions) > 0 ? var.sns_topic_subscriptions : (
    var.sns_topic_subscription_email != "" ? {
      email = {
        protocol = "email"
        endpoint = var.sns_topic_subscription_email
      }
    } : {}
  )

  default_eventbridge_rules = merge(
    var.enable_kms_deletion_alert ? {
      kms_key_scheduled_deletion = {
        description = "KMS Key scheduled for deletion"
        event_pattern = jsonencode({
          source        = ["aws.kms"]
          "detail-type" = ["AWS API Call via CloudTrail"]
          detail = {
            eventSource = ["kms.amazonaws.com"]
            eventName   = ["ScheduleKeyDeletion"]
          }
        })
        enabled = true
      }
    } : {},
    var.enable_kms_disabled_alert ? {
      kms_key_disabled = {
        description = "KMS Key disabled"
        event_pattern = jsonencode({
          source        = ["aws.kms"]
          "detail-type" = ["AWS API Call via CloudTrail"]
          detail = {
            eventSource = ["kms.amazonaws.com"]
            eventName   = ["DisableKey"]
          }
        })
        enabled = true
      }
    } : {}
  )

  default_eventbridge_targets = merge(
    var.enable_kms_deletion_alert ? {
      kms_key_scheduled_deletion = [
        {
          name = "send-kms-deletion-notification"
          arn  = local.sns_topic_arn
          id   = "send-kms-deletion-notification"
          input_transformer = {
            input_paths = {
              event_time    = "$.detail.eventTime"
              aws_account   = "$.detail.userIdentity.accountId"
              user_arn      = "$.detail.userIdentity.arn"
              source_ip     = "$.detail.sourceIPAddress"
              user_agent    = "$.detail.userAgent"
              region        = "$.detail.awsRegion"
              key_id        = "$.detail.requestParameters.keyId"
              key_arn       = "$.detail.responseElements.keyId"
              pending_days  = "$.detail.responseElements.pendingWindowInDays"
              deletion_date = "$.detail.responseElements.deletionDate"
              request_id    = "$.detail.requestID"
            }
            input_template = <<-EOT
              "A KMS key has been scheduled for deletion in your account."

              "Event Time: <event_time>"
              "AWS Account: <aws_account>"
              "AWS Region: <region>"

              "Key ID: <key_id>"
              "Key ARN: <key_arn>"
              "Scheduled Deletion Date: <deletion_date>"
              "Pending Window: <pending_days> days"

              "Source IP: <source_ip>"
              "User Agent: <user_agent>"
              "Initiated by: <user_arn>"
              "Request ID: <request_id>"

              "🚨 Immediate Action Required: Verify if this was intentional! 🚨"
            EOT
          }
        }
      ]
    } : {},
    var.enable_kms_disabled_alert ? {
      kms_key_disabled = [
        {
          name = "send-kms-disable-notification"
          arn  = local.sns_topic_arn
          id   = "send-kms-disable-notification"
          input_transformer = {
            input_paths = {
              key_id      = "$.detail.requestParameters.keyId"
              key_arn     = "$.detail.responseElements.keyId"
              aws_account = "$.detail.userIdentity.accountId"
              user_arn    = "$.detail.userIdentity.arn"
              event_time  = "$.detail.eventTime"
              source_ip   = "$.detail.sourceIPAddress"
              user_agent  = "$.detail.userAgent"
              region      = "$.detail.awsRegion"
              request_id  = "$.detail.requestID"
            }
            input_template = <<-EOT
              "A KMS key has been disabled in your account."

              "Event Time: <event_time>"
              "AWS Account: <aws_account>"
              "AWS Region: <region>"

              "Key ID: <key_id>"
              "Key ARN: <key_arn>"

              "Source IP: <source_ip>"
              "User Agent: <user_agent>"
              "Initiated by: <user_arn>"
              "Request ID: <request_id>"

              "🚨 Immediate Action Required: Verify if this was intentional! 🚨"
            EOT
          }
        }
      ]
    } : {}
  )

  notifications_eventbridge_rules   = merge(local.default_eventbridge_rules, var.notifications_eventbridge_rules)
  notifications_eventbridge_targets = merge(local.default_eventbridge_targets, var.notifications_eventbridge_targets)

  create_eventbridge = length(local.notifications_eventbridge_rules) > 0
  eventbridge_role_name = coalesce(
    var.eventbridge_role_name != "" ? var.eventbridge_role_name : null,
    "eventbridge-notifications-role-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"
  )
}

module "sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "7.1.0"

  count = var.create_sns_topic ? 1 : 0

  name = var.sns_topic_name

  subscriptions = local.sns_subscriptions
}

module "eventbridge_notifications" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "4.3.0"

  count = local.create_eventbridge ? 1 : 0

  create                     = true
  create_bus                 = false
  create_log_delivery_source = false

  role_name = local.eventbridge_role_name

  rules   = local.notifications_eventbridge_rules
  targets = local.notifications_eventbridge_targets
}