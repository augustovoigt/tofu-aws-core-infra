###################################################################
# General
###################################################################

variable "aws_region" {
  description = "AWS Region where resources will be provisioned."
  type        = string

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must be a non-empty string."
  }
}

variable "aws_account_id" {
  description = "AWS Account ID for resource provisioning."
  type        = string

  validation {
    condition     = length(trimspace(var.aws_account_id)) > 0
    error_message = "aws_account_id must be a non-empty string."
  }
}

variable "resource_prefix" {
  description = "Resource prefix for AWS Core resources. Needs to be unique per AWS (sub) account."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_prefix)) > 0
    error_message = "resource_prefix must be a non-empty string."
  }
}

variable "environments" {
  description = "A list of environment names (e.g., prod, qa, staging) deployed in this infrastructure. Used to provision resources per environment."
  type        = list(string)
  default     = ["prod", "qa", "staging"]

  validation {
    condition     = length(var.environments) == length(distinct(var.environments))
    error_message = "environments must not contain duplicate values."
  }

  validation {
    condition     = alltrue([for e in var.environments : length(trimspace(e)) > 0])
    error_message = "environments must not contain empty strings."
  }
}

###################################################################
# S3
###################################################################

variable "create_s3" {
  description = "Create S3 buckets and supporting objects used by this module (e.g., bucket for lambda layers)."
  type        = bool
  default     = true

  validation {
    condition = var.create_s3 || (
      !var.create_layer_request &&
      !var.create_layer_tabulate &&
      !var.create_layer_valkey_client &&
      !var.create_layer_oracledb &&
      !var.create_layer_mysqldb &&
      !var.create_layer_cryptography
    )
    error_message = "create_s3 is false, but one or more lambda layer create flags are true. Disable the layers or enable create_s3."
  }
}

variable "s3_buckets" {
  description = "Map of S3 buckets to create. Keys are logical identifiers; values are passed into terraform-aws-modules/s3-bucket."
  type        = any
  default     = {}
}

###################################################################
# RDS - Options and Parameter Groups
###################################################################

variable "create_rds_option_groups" {
  description = "Create RDS option groups."
  type        = bool
  default     = true
}

variable "create_rds_parameter_groups" {
  description = "Create RDS parameter groups."
  type        = bool
  default     = true
}

variable "rds_option_groups" {
  description = "Map of option groups to create. Keys are logical identifiers; values define name/engine/options."
  type        = any
  default     = {}
}

variable "rds_parameter_groups" {
  description = "Map of parameter groups to create. Keys are logical identifiers; values define name/family/parameters."
  type        = any
  default     = {}
}

###################################################################
# WAF
###################################################################

variable "create_waf" {
  description = "Create AWS WAF resources (using tofu-aws-modules WAF module)."
  type        = bool
  default     = false
}

variable "waf" {
  description = "WAF module input overrides. Merged on top of the defaults defined in waf.tf locals."
  type        = any
  default     = {}
}

###################################################################
# Secrets Manager
###################################################################

variable "create_secrets_manager" {
  description = "Create AWS Secrets Manager secrets managed by this module."
  type        = bool
  default     = true
}

variable "app_env_secrets" {
  description = "Per-environment Secrets Manager secret configuration overrides for the AppServer credentials. Merged on top of defaults in secrets-manager.tf."
  type        = any
  default     = {}
}

###################################################################
# IAM Role ARNs (from global module)
###################################################################

variable "iam_role_rds_enhanced_monitoring_arn" {
  description = "IAM Role ARN for RDS Enhanced Monitoring. Required when create_lambda_rds_modify_instance=true."
  type        = string
  default     = null

  validation {
    condition = (
      !var.create_lambda_rds_modify_instance || (
        var.iam_role_rds_enhanced_monitoring_arn != null && trimspace(var.iam_role_rds_enhanced_monitoring_arn) != ""
      )
      ) && (
      var.iam_role_rds_enhanced_monitoring_arn == null || trimspace(var.iam_role_rds_enhanced_monitoring_arn) == "" || (
        startswith(trimspace(var.iam_role_rds_enhanced_monitoring_arn), "arn:") &&
        strcontains(trimspace(var.iam_role_rds_enhanced_monitoring_arn), ":iam::${var.aws_account_id}:role/")
      )
    )
    error_message = "iam_role_rds_enhanced_monitoring_arn must be set when create_lambda_rds_modify_instance is true and must reference an IAM role in aws_account_id."
  }
}

variable "iam_role_rds_s3_integration_arn" {
  description = "IAM Role ARN for RDS S3 integration. Required when create_lambda_rds_modify_instance=true."
  type        = string
  default     = null

  validation {
    condition = (
      !var.create_lambda_rds_modify_instance || (
        var.iam_role_rds_s3_integration_arn != null && trimspace(var.iam_role_rds_s3_integration_arn) != ""
      )
      ) && (
      var.iam_role_rds_s3_integration_arn == null || trimspace(var.iam_role_rds_s3_integration_arn) == "" || (
        startswith(trimspace(var.iam_role_rds_s3_integration_arn), "arn:") &&
        strcontains(trimspace(var.iam_role_rds_s3_integration_arn), ":iam::${var.aws_account_id}:role/")
      )
    )
    error_message = "iam_role_rds_s3_integration_arn must be set when create_lambda_rds_modify_instance is true and must reference an IAM role in aws_account_id."
  }
}

###################################################################
# Lambdas - Create flags
###################################################################

variable "create_lambda_rds_delete_instance" {
  description = "Create the Lambda function lambda-rds-delete-instance and its IAM role."
  type        = bool
  default     = true
}

variable "create_lambda_rds_modify_instance" {
  description = "Create the Lambda function lambda-rds-modify-instance and its IAM role."
  type        = bool
  default     = true
}

variable "create_lambda_rds_create_snapshot" {
  description = "Create the Lambda function lambda-rds-create-snapshot and its IAM role."
  type        = bool
  default     = true
}

variable "create_lambda_rds_delete_snapshot" {
  description = "Create the Lambda function lambda-rds-delete-snapshot and its IAM role."
  type        = bool
  default     = true
}

variable "create_lambda_rds_restore_snapshot" {
  description = "Create the Lambda function lambda-rds-restore-snapshot and its IAM role."
  type        = bool
  default     = true
}

variable "create_lambda_rds_start_stop_instance" {
  description = "Create the Lambda function lambda-rds-start-stop-instance and its IAM role."
  type        = bool
  default     = true
}

variable "create_lambda_rds_status_check" {
  description = "Create the Lambda function lambda-rds-status-check and its IAM role."
  type        = bool
  default     = true
}

variable "create_lambda_rds_modify_instance_version_update" {
  description = "Create the Lambda function lambda-rds-modify-instance-version-update and its IAM role."
  type        = bool
  default     = true
}

###################################################################
# Lambda Layers - Create flags
###################################################################


variable "create_layer_request" {
  description = "Create the Lambda layer layer-request."
  type        = bool
  default     = true
}

variable "create_layer_tabulate" {
  description = "Create the Lambda layer layer-tabulate."
  type        = bool
  default     = true
}

variable "create_layer_valkey_client" {
  description = "Create the Lambda layer layer-valkey-client."
  type        = bool
  default     = true
}

variable "create_layer_oracledb" {
  description = "Create the Lambda layer layer-oracledb."
  type        = bool
  default     = true
}

variable "create_layer_mysqldb" {
  description = "Create the Lambda layer layer-mysqldb."
  type        = bool
  default     = true
}

variable "create_layer_cryptography" {
  description = "Create the Lambda layer layer-cryptography."
  type        = bool
  default     = true
}

###################################################################
# AWS Notifications (SNS) variables
###################################################################

variable "create_sns_topic" {
  type        = bool
  description = "Create SNS topic for notifications."
  default     = false
}

variable "sns_topic_name" {
  type        = string
  description = "Name of the SNS topic."
  default     = "platform-ops-notifications"
}

variable "sns_topic_subscription_email" {
  type        = string
  description = "Email address to subscribe to the notifications SNS topic."
  default     = ""

  validation {
    condition = var.sns_topic_subscription_email == "" || (
      strcontains(var.sns_topic_subscription_email, "@") &&
      length(split("@", var.sns_topic_subscription_email)) == 2 &&
      length(trimspace(split("@", var.sns_topic_subscription_email)[0])) > 0 &&
      length(trimspace(split("@", var.sns_topic_subscription_email)[1])) > 0 &&
      strcontains(split("@", var.sns_topic_subscription_email)[1], ".")
    )
    error_message = "The value of sns_topic_subscription_email must look like an email address if provided."
  }
}

variable "sns_topic_subscriptions" {
  description = "Optional SNS subscriptions map passed to terraform-aws-modules/sns. When set (non-empty), it overrides sns_topic_subscription_email."
  type = map(object({
    protocol = string
    endpoint = string
  }))
  default = {}
}

variable "sns_topic_arn_override" {
  description = "Use an existing SNS Topic ARN if not creating one with Terraform."
  type        = string
  default     = ""

  validation {
    condition = var.create_sns_topic || (
      trimspace(var.sns_topic_arn_override) != "" &&
      startswith(trimspace(var.sns_topic_arn_override), "arn:") &&
      strcontains(trimspace(var.sns_topic_arn_override), ":sns:${var.aws_region}:${var.aws_account_id}:")
    )
    error_message = "If create_sns_topic is false, you must provide a valid AWS SNS Topic ARN."
  }
}

###################################################################
# AWS Eventbridge rules for notifications
###################################################################

variable "enable_kms_disabled_alert" {
  type        = bool
  default     = false
  description = "Enable alert for KMS key being disabled."
}

variable "enable_kms_deletion_alert" {
  type        = bool
  default     = false
  description = "Enable alert for KMS key scheduled for deletion."
}

variable "eventbridge_role_name" {
  description = "Optional fixed EventBridge IAM role name used by notification rules. If empty, a default name is generated."
  type        = string
  default     = ""
}

variable "notifications_eventbridge_rules" {
  description = "Additional/override EventBridge rules map (merged on top of the defaults when enabled)."
  type        = any
  default     = {}
}

variable "notifications_eventbridge_targets" {
  description = "Additional/override EventBridge targets map (merged on top of the defaults when enabled)."
  type        = any
  default     = {}
}

###################################################################
# VPC
###################################################################

variable "create_vpc" {
  description = "Controls if VPC should be created (it affects almost all resources)"
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "VPC subnet in CIDR notation."
  type        = string
  default     = ""

  validation {
    condition = (
      !var.create_vpc || length(trimspace(var.vpc_cidr)) > 0
      ) && (
      length(trimspace(var.vpc_cidr)) == 0 || can(cidrhost(var.vpc_cidr, 0))
    )
    error_message = "vpc_cidr must be a valid CIDR when set and is required when create_vpc is true."
  }
}

variable "create_database_subnet_group" {
  description = "Controls if database subnet group should be created (n.b. database_subnets must also be set)"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs`"
  type        = bool
  default     = false
}

variable "create_igw" {
  description = "Controls if an Internet Gateway is created for public subnets and the related routes that connect them"
  type        = bool
  default     = false
}

variable "map_public_ip_on_launch" {
  description = "Controls if instances launched in the public subnets should receive a public IP address."
  type        = bool
  default     = false
}

# VPC Endpoints

variable "gateway_endpoints" {
  description = "List of services to create VPC Gateway endpoints for."
  type        = list(string)
  default     = ["s3"]
}

###################################################################
# SSM Jumpbox
###################################################################

variable "create_ssm_jumpbox" {
  description = "Enable or disable the creation of the SSM jumpbox resources."
  type        = bool
  default     = false
}

variable "ssm_jumpbox_desired_capacity" {
  description = "Desired number of SSM jumpbox instances. Set to 1 to launch, 0 to terminate."
  type        = number
  default     = 1
}

variable "ssm_jumpbox_instance_type" {
  description = "The EC2 instance type for the SSM jumpbox."
  type        = string
  default     = "t4g.micro"
}