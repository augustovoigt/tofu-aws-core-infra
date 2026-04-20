###################################################################
# General
###################################################################

variable "context" {
  description = "Select which core-infra context to deploy from this root module: global, regional, or vpc-scoped. Each one has a unique state and set of resources it manages. global is for global-level resources (e.g., IAM roles not specific to a region or cluster), regional is for region-specific resources (e.g., RDS option groups, S3 buckets), and vpc-scoped is for VPC-attached resources (e.g., ArgoCD, VPC-attached Lambdas)."
  type        = string

  validation {
    condition     = contains(["global", "regional", "vpc-scoped"], var.context)
    error_message = "context must be one of: global, regional, vpc-scoped."
  }
}

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

###################################################################
# IAM Role
###################################################################

variable "create_iam_role_eventbridge_scheduler" {
  description = "Create the IAM Role for the Eventbridge Scheduler."
  type        = bool
  default     = true
}

variable "create_iam_role_rds_enhanced_monitoring" {
  description = "Create the IAM Role for Enhanced Monitoring."
  type        = bool
  default     = true
}

variable "create_iam_role_rds_s3_integration" {
  description = "Create the IAM Role to integrate the RDS with central S3 bucket."
  type        = bool
  default     = true
}

variable "create_iam_role_cross_account_finops" {
  description = "Create the IAM role to grant read only access to the FinOps AWS account."
  type        = bool
  default     = false
}

variable "iam_roles" {
  description = "IAM role definitions to merge with defaults in global/cluster IAM modules. Values in var.iam_roles override defaults on key conflicts."
  type        = any
  default     = {}
}

###################################################################
# Regional variables
###################################################################

# S3

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

# RDS - Options and Parameter Groups

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

# WAF

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

# Secrets Manager

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

# IAM Role ARNs (from global module)

variable "iam_role_rds_enhanced_monitoring_arn" {
  description = "IAM Role ARN for RDS Enhanced Monitoring. Required when create_lambda_rds_modify_instance=true."
  type        = string
  default     = null

  validation {
    condition = var.context != "regional" || (
      (!var.create_lambda_rds_modify_instance || (
        var.iam_role_rds_enhanced_monitoring_arn != null && trimspace(var.iam_role_rds_enhanced_monitoring_arn) != ""
        )) && (
        var.iam_role_rds_enhanced_monitoring_arn == null || trimspace(var.iam_role_rds_enhanced_monitoring_arn) == "" || (
          startswith(trimspace(var.iam_role_rds_enhanced_monitoring_arn), "arn:") &&
          strcontains(trimspace(var.iam_role_rds_enhanced_monitoring_arn), ":iam::${var.aws_account_id}:role/")
        )
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
    condition = var.context != "regional" || (
      (!var.create_lambda_rds_modify_instance || (
        var.iam_role_rds_s3_integration_arn != null && trimspace(var.iam_role_rds_s3_integration_arn) != ""
        )) && (
        var.iam_role_rds_s3_integration_arn == null || trimspace(var.iam_role_rds_s3_integration_arn) == "" || (
          startswith(trimspace(var.iam_role_rds_s3_integration_arn), "arn:") &&
          strcontains(trimspace(var.iam_role_rds_s3_integration_arn), ":iam::${var.aws_account_id}:role/")
        )
      )
    )
    error_message = "iam_role_rds_s3_integration_arn must be set when create_lambda_rds_modify_instance is true and must reference an IAM role in aws_account_id."
  }
}

# Lambdas - Create flags

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

# Lambda Layers - Create flags

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

# AWS Notifications (SNS) variables

variable "create_sns_topic" {
  type        = bool
  description = "Create SNS topic for notifications."
  default     = false

  validation {
    condition     = var.context != "regional" || var.create_sns_topic != null
    error_message = "create_sns_topic must be set when context is 'regional'."
  }
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
    condition = var.context != "regional" || (var.create_sns_topic == true) || (
      trimspace(var.sns_topic_arn_override) != "" &&
      startswith(trimspace(var.sns_topic_arn_override), "arn:") &&
      strcontains(trimspace(var.sns_topic_arn_override), ":sns:${var.aws_region}:${var.aws_account_id}:")
    )
    error_message = "If create_sns_topic is false, you must provide a valid AWS SNS Topic ARN."
  }
}

# AWS Eventbridge rules for notifications

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
# VPC-Scoped
###################################################################

# Platform state inputs (passed explicitly by infra)

variable "vpc_id" {
  description = "VPC ID where vpc-scoped resources are deployed."
  type        = string
  default     = null

  validation {
    condition     = var.context != "vpc-scoped" || (var.vpc_id != null && length(trimspace(var.vpc_id)) > 0)
    error_message = "vpc_id must be a non-empty string."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used for VPC-attached Lambdas."
  type        = list(string)
  default     = null

  validation {
    condition     = var.context != "vpc-scoped" || (var.private_subnet_ids != null && length(var.private_subnet_ids) > 0)
    error_message = "private_subnet_ids must contain at least one subnet id."
  }

  validation {
    condition     = var.context != "vpc-scoped" || (var.private_subnet_ids != null && alltrue([for id in var.private_subnet_ids : length(trimspace(id)) > 0]))
    error_message = "private_subnet_ids must not contain empty strings."
  }
}

variable "public_subnet_ids" {
  description = "Public subnet IDs that can be used by internet-facing resources such as an ALB."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.public_subnet_ids : length(trimspace(id)) > 0])
    error_message = "public_subnet_ids must not contain empty strings."
  }
}

variable "aws_service_base_security_group_id" {
  description = "Security Group ID used by AWS service base workloads (used by VPC-attached Lambdas)."
  type        = string
  default     = null
}

variable "elasticache_security_group_id" {
  description = "Security Group ID for Elasticache/Valkey."
  type        = string
  default     = null
}

variable "elasticache_subnet_group_name" {
  description = "Subnet group name for Elasticache/Valkey."
  type        = string
  default     = null
}

variable "base_security_group_tags" {
  description = "Tags for the base security group."
  type        = map(string)
  default     = {}
}

variable "public_subnet_id" {
  description = "List of public subnet IDs to use for cluster resources."
  type        = list(string)
  default     = []
}

# EKS Cluster

variable "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN (used for IAM roles for service accounts)."
  type        = string
  default     = null
}

variable "eks_oidc_provider" {
  description = "EKS OIDC provider URL/identifier."
  type        = string
  default     = null
}

# Argocd

variable "create_argocd_apps" {
  description = "Feature flag to enable/disable Argo CD projects and applications (argocd-apps Helm release). When false, no Argo CD apps/projects are created by this stack."
  type        = bool
  default     = false
}

variable "apps_chart_version" {
  description = "The version of the Argo CD Apps Helm chart."
  type        = string
  # renovate: datasource=helm registryUrl=https://argoproj.github.io/argo-helm depName=argocd-apps
  default = "2.0.2"
}

variable "sync_windows_ops" {
  description = "ArgoCD sync windows for the platform-ops projects."
  type = list(object({
    kind         = optional(string, "allow")
    schedule     = optional(string, "0 12 * * 1")
    duration     = optional(string, "1h")
    timeZone     = optional(string, "")
    manualSync   = optional(bool, true)
    namespaces   = optional(list(string), ["*"])
    clusters     = optional(list(string), ["*"])
    applications = optional(list(string), ["*"])
  }))

  default = []
}

variable "sync_windows_ops_customers" {
  description = "ArgoCD sync windows for the platform-ops-customers project."
  type = list(object({
    kind         = optional(string, "allow")
    schedule     = optional(string, "0 12 * * 1")
    duration     = optional(string, "1h")
    timeZone     = optional(string, "")
    manualSync   = optional(bool, true)
    namespaces   = optional(list(string), ["*"])
    clusters     = optional(list(string), ["*"])
    applications = optional(list(string), ["*"])
  }))

  default = [
    {
      kind         = "allow"
      schedule     = "0 12 * * 1"
      duration     = "1h"
      timeZone     = ""
      manualSync   = true
      namespaces   = ["*"]
      clusters     = ["*"]
      applications = ["*"]
    },
  ]
}

variable "sync_windows_ops_internal" {
  description = "ArgoCD sync windows for the platform-ops-internal project."
  type = list(object({
    kind         = optional(string, "allow")
    schedule     = optional(string, "0 12 * * 1")
    duration     = optional(string, "1h")
    timeZone     = optional(string, "")
    manualSync   = optional(bool, true)
    namespaces   = optional(list(string), ["*"])
    clusters     = optional(list(string), ["*"])
    applications = optional(list(string), ["*"])
  }))

  default = [
    {
      kind         = "allow"
      schedule     = "0 12 * * 1"
      duration     = "1h"
      timeZone     = ""
      manualSync   = true
      namespaces   = ["*"]
      clusters     = ["*"]
      applications = ["*"]
    },
  ]
}

variable "addons_enable" {
  description = "Enable or disable Argo Managed addons in the cluster."
  type        = bool
  default     = true
}

variable "addons_revision" {
  description = "The revision of the Argo Managed addons to apply in the cluster."
  type        = string
  default     = "dev"
}

variable "addons_crossplane_providers" {
  description = "Configuration for Crossplane Providers to be enabled as part of the addons installation."
  type = object({
    enabled = bool

    upboundProviderAwsEC2 = optional(object({
      enabled = bool
    }), null)
  })
  default = {
    enabled = false
  }
}

variable "addons_enable_github_runners" {
  description = "Enable or disable Github Runners in the addons installation."
  type        = bool
  default     = false
}

variable "addons_enable_kubernetes_event_exporter" {
  description = "Enable or disable Kubernetes Event Exporter in the addons installation."
  type        = bool
  default     = false
}

variable "addons_enable_monitoring" {
  description = "Enable or disable Monitoring in the addons installation."
  type        = bool
  default     = false
}

variable "addons_enable_stakater_reloader" {
  description = "Enable or disable Stakater Reloader in the addons installation."
  type        = bool
  default     = false
}

variable "addons_enable_pci_addons" {
  description = "Enable or disable PCI Addons in the addons installation."
  type        = bool
  default     = false
}

variable "addons_enable_pci_addons_patches" {
  description = "Enable or disable pci-addons patches."
  type        = bool
  default     = false
}

variable "addons_enable_pci_addons_efs_csi_driver" {
  description = "Enable or disable pci-addons efs-csi-driver."
  type        = bool
  default     = false
}

variable "customers_revision" {
  description = "The revision of the customers app to monitor the platform-ops-argocd-infra repository."
  type        = string
  default     = "main"
}

variable "internal_revision" {
  description = "The revision of the internal app to monitor the platform-ops-argocd-infra repository."
  type        = string
  default     = "main"
}

# Argocd Repocreds

variable "argocd_addons_repo_list_names" {
  type        = list(string)
  description = "Defines a list of Github repositories names to create the kubernetes secret to authenticate this repositories on ArgoCD."
  default     = ["argocd-infra", "platform-ops-charts", "platform-charts"]
}

variable "argocd_addons_repo_creds_app_id" {
  type        = string
  description = "Defines the Github App ID."
  sensitive   = false
  default     = null
}

variable "argocd_addons_repo_creds_app_installation_id" {
  type        = string
  description = "Defines the Github installation ID."
  default     = null
}

variable "argocd_addons_repo_creds_private_key" {
  type        = string
  description = "Defines the Github private key."
  sensitive   = true
  default     = null
}

variable "create_argocd_repocreds" {
  description = "Whether to create ArgoCD repo-creds Secrets from the default repo list (argocd_addons_repo_list_names)."
  type        = bool
  default     = false
}

variable "argocd_repocreds" {
  description = "ArgoCD repo-creds Secret overrides/additions keyed by logical id (typically the repo name). Merged on top of local defaults in argocd-repocreds.tf. Set create=false to disable a secret."
  type        = any
  default     = {}
}

# Nodepools

variable "create_nodepool" {
  description = "Whether to create Karpenter NodePool manifests from nodepools.tf. When false, no NodePool resources are created."
  type        = bool
  default     = false
}

variable "nodepools" {
  description = "NodePool manifest overrides/additions keyed by nodepool name. Merged on top of local defaults in nodepools.tf."
  type        = any
  default     = {}
}

# Priority Classes

variable "create_priority_class" {
  description = "Whether to create Kubernetes PriorityClass resources from the vpc-scoped module. When false, no PriorityClass resources are created."
  type        = bool
  default     = false
}

variable "priority_classes" {
  description = "Kubernetes PriorityClass overrides/additions keyed by logical id. Merged on top of local defaults in priority-class.tf. Each value should include at least 'value' (number) and optionally 'metadata.name', 'global_default', 'preemption_policy', 'description'."
  type        = any
  default     = {}
}

# Namespaces

variable "namespaces" {
  description = "Kubernetes namespace overrides/additions keyed by logical id. Merged on top of local defaults in namespace.tf. Set create=false to disable a namespace."
  type        = any
  default     = {}
}

variable "create_namespace_platform_ops" {
  description = "Whether to create the Kubernetes namespace 'platform-ops'."
  type        = bool
  default     = false
}

variable "create_namespace_platform_ops_addons" {
  description = "Whether to create the Kubernetes namespace 'platform-ops-addons'."
  type        = bool
  default     = false
}

variable "create_namespace_platform_ops_customers" {
  description = "Whether to create the Kubernetes namespace 'platform-ops-customers'."
  type        = bool
  default     = false
}

variable "create_namespace_platform_ops_internal" {
  description = "Whether to create the Kubernetes namespace 'platform-ops-internal'."
  type        = bool
  default     = false
}

###################################################################
# IAM roles
###################################################################

variable "create_iam_role_cloudwatch_exporter" {
  description = "Create the IAM role used by the cloudwatch-exporter service account."
  type        = bool
  default     = true
}

variable "create_iam_role_prometheus_rds_exporter" {
  description = "Create the IAM role used by the prometheus-rds-exporter service account."
  type        = bool
  default     = true
}

variable "create_iam_role_finops_cronjob" {
  description = "Create the IAM role used by the finops cronjob service account."
  type        = bool
  default     = true
}

variable "create_iam_role_step_functions_dump_rds" {
  description = "Create the IAM role used by the dump-rds Step Functions state machine."
  type        = bool
  default     = true
}

variable "create_iam_role_step_functions_version_update" {
  description = "Create the IAM role used by the version-update Step Functions state machine."
  type        = bool
  default     = true
}

###################################################################
# Lambdas
###################################################################

variable "create_lambda_rds_oracle_execute_sql_statements" {
  description = "Create the Lambda function lambda-rds-oracle-execute-sql-statements and its IAM role."
  type        = bool
  default     = true
}

variable "create_lambda_rds_oracle_update_users_credentials" {
  description = "Create the Lambda function lambda-rds-oracle-update-users-credentials and its IAM role."
  type        = bool
  default     = true
}

variable "create_lambda_valkey_clear_cache" {
  description = "Create the Lambda function lambda-valkey-clear-cache and its IAM role."
  type        = bool
  default     = true
}

variable "create_lambda_secretsmanager_rds_oracle_password_rotation" {
  description = "Create the Lambda function lambda-secretsmanager-rds-oracle-password-rotation and its IAM role."
  type        = bool
  default     = true
}

variable "create_lambda_secretsmanager_rds_mysql_password_rotation" {
  description = "Create the Lambda function lambda-secretsmanager-rds-mysql-password-rotation and its IAM role."
  type        = bool
  default     = true
}

###################################################################
# Lambda Layers
###################################################################

variable "lambda_layer_request_arn" {
  description = "ARN of the regional Lambda layer: request."
  type        = string
  default     = null
}

variable "lambda_layer_tabulate_arn" {
  description = "ARN of the regional Lambda layer: tabulate."
  type        = string
  default     = null
}

variable "lambda_layer_valkey_client_arn" {
  description = "ARN of the regional Lambda layer: valkey-client."
  type        = string
  default     = null
}

variable "lambda_layer_oracledb_arn" {
  description = "ARN of the regional Lambda layer: oracledb."
  type        = string
  default     = null
}

variable "lambda_layer_mysqldb_arn" {
  description = "ARN of the regional Lambda layer: mysqldb."
  type        = string
  default     = null
}

variable "lambda_layer_cryptography_arn" {
  description = "ARN of the regional Lambda layer: cryptography."
  type        = string
  default     = null
}

###################################################################
# Lambda Function ARNs (used by Step Functions)
###################################################################

variable "lambda_rds_create_snapshot_arn" {
  description = "Lambda Function ARN for regional lambda_rds_create_snapshot."
  type        = string
  default     = null
}

variable "lambda_rds_delete_instance_arn" {
  description = "Lambda Function ARN for regional lambda_rds_delete_instance."
  type        = string
  default     = null
}

variable "lambda_rds_restore_snapshot_arn" {
  description = "Lambda Function ARN for regional lambda_rds_restore_snapshot."
  type        = string
  default     = null
}

variable "lambda_rds_modify_instance_arn" {
  description = "Lambda Function ARN for regional lambda_rds_modify_instance."
  type        = string
  default     = null
}

variable "lambda_rds_delete_snapshot_arn" {
  description = "Lambda Function ARN for regional lambda_rds_delete_snapshot."
  type        = string
  default     = null
}

variable "lambda_rds_status_check_arn" {
  description = "Lambda Function ARN for regional lambda_rds_status_check."
  type        = string
  default     = null
}

variable "lambda_rds_modify_instance_version_update_arn" {
  description = "Lambda Function ARN for regional lambda_rds_modify_instance_version_update."
  type        = string
  default     = null
}

###################################################################
# Step Functions
###################################################################

variable "create_step_function_dump_rds" {
  description = "Feature flag to enable/disable all Step Functions state machines in this module. When false, no Step Functions are created (module for_each becomes empty)."
  type        = bool
  default     = true
}

variable "create_step_function_version_update" {
  description = "Feature flag to enable/disable all Step Functions state machines in this module. When false, no Step Functions are created (module for_each becomes empty)."
  type        = bool
  default     = true
}

variable "step_functions" {
  description = "Step Functions module input overrides merged on top of local defaults in step-functions.tf. Use this to override name/definition/logging/timeouts or to disable a state machine by setting create=false."
  type        = any
  default     = {}
}

###################################################################
# Security Groups
###################################################################

variable "create_sg_custom" {
  description = "Create the custom security group (sg-custom)."
  type        = bool
  default     = false
}

variable "sg_custom_ips" {
  description = "Comma-separated CIDR blocks allowed to reach Oracle (1521) and MySQL (3306) through sg-custom. Example: '1.2.3.4/32,5.6.7.8/32'."
  type        = string
  default     = ""
}

variable "security_groups" {
  description = "Security Group module input overrides merged on top of local defaults in security-groups.tf. Use this to override name/description/ingress/egress/tags or to disable a SG by setting create=false."
  type        = any
  default     = {}
}

variable "create_sg_internal_ips" {
  description = "Create the security group that allows ingress from the managed prefix list (internal_ips)."
  type        = bool
  default     = false
}

variable "sg_internal_ips_list" {
  description = "Additional CIDR blocks allowed as ingress (all protocols/ports). Example: ['1.2.3.4/32','5.6.7.8/32']."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.sg_internal_ips_list : can(cidrhost(c, 0))])
    error_message = "sg_internal_ips_list must contain valid CIDR blocks."
  }
}

variable "create_sg_external_ips" {
  description = "Create the external security group (external_ips)."
  type        = bool
  default     = false
}

variable "sg_external_ips_list" {
  description = "CIDR blocks allowed as ingress on external_ips (all protocols/ports). Starts empty and can be expanded when external IPs are provided."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.sg_external_ips_list : can(cidrhost(c, 0))])
    error_message = "sg_external_ips_list must contain valid CIDR blocks."
  }
}

###################################################################
# Valkey (ElastiCache)
###################################################################

variable "create_valkey" {
  description = "Create the Valkey (ElastiCache) replication group."
  type        = bool
  default     = true
}

variable "valkey_engine_version" {
  description = "Valkey engine version used by ElastiCache."
  type        = string
  default     = "8.0"
}

variable "valkey_node_type" {
  description = "ElastiCache node type for Valkey (e.g., cache.t4g.small)."
  type        = string
  default     = "cache.t3.small"
}

variable "valkey_multi_az" {
  description = "Enable Multi-AZ for Valkey. When true, two cache clusters are created with automatic failover enabled."
  type        = bool
  default     = false
}

variable "valkey_maintenance_window" {
  description = "Maintenance window for Valkey (UTC). Example: 'Mon:00:00-Mon:03:00'."
  type        = string
  default     = "sun:00:00-sun:04:00"
}

variable "valkeys" {
  description = "Valkey/ElastiCache module input overrides merged on top of local defaults in valkey.tf. Use this to override module inputs or to disable a cluster by setting create=false."
  type        = any
  default     = {}
}

variable "create_valkey_security_group" {
  description = "Determines if a security group for Valkey is created"
  type        = bool
  default     = false
}

variable "create_valkey_subnet_group" {
  description = "Determines whether the Elasticache subnet group for Valkey will be created or not"
  type        = bool
  default     = false
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
# ECS Cluster
###################################################################

variable "create_ecs_cluster" {
  description = "Determines whether the ECS cluster will be created"
  type        = bool
  default     = false
}

variable "ecs_mi_on_demand_memory_mib" {
  description = "Memory requirements (min/max in MiB) for ECS Managed Instances on-demand capacity provider."
  type = object({
    min = number
    max = number
  })
  default = {
    min = 1024
    max = 8192
  }
}

variable "ecs_mi_on_demand_vcpu_count" {
  description = "vCPU requirements (min/max) for ECS Managed Instances on-demand capacity provider."
  type = object({
    min = number
    max = number
  })
  default = {
    min = 1
    max = 4
  }
}

variable "ecs_mi_spot_memory_mib" {
  description = "Memory requirements (min/max in MiB) for ECS Managed Instances spot capacity provider."
  type = object({
    min = number
    max = number
  })
  default = {
    min = 1024
    max = 8192
  }
}

variable "ecs_mi_spot_vcpu_count" {
  description = "vCPU requirements (min/max) for ECS Managed Instances spot capacity provider."
  type = object({
    min = number
    max = number
  })
  default = {
    min = 1
    max = 4
  }
}

variable "ecs_mi_storage_size_gib" {
  description = "Storage size in GiB for ECS Managed Instances."
  type        = number
  default     = 50
}

variable "ecs_mi_spot_max_price_percentage" {
  description = "Maximum price percentage over lowest price for spot instances."
  type        = number
  default     = 20
}

variable "ecs_ingress_rules" {

  description = "Ingress rules for ECS instances"

  type = list(object({
    port = number
    cidr = string
  }))

  default = []
}

variable "ecs_create_cloud_map_namespace" {
  description = "Create a private Cloud Map namespace for ECS Service Connect"
  type        = bool
  default     = true
}

variable "ecs_cloud_map_namespace_name" {
  description = "Private DNS namespace name for ECS Service Connect (e.g. svc.local). If null, uses <resource_prefix>.local"
  type        = string
  default     = null
}

###################################################################
# Load Balancer
###################################################################

variable "create_alb_public" {
  description = "Determines whether the public (internet-facing) Application Load Balancer will be created."
  type        = bool
  default     = false
}

variable "create_alb_internal" {
  description = "Determines whether the internal Application Load Balancer will be created."
  type        = bool
  default     = false
}

variable "alb_public_certificate_arn" {
  description = "ACM certificate ARN used by the HTTPS listener on the public ALB."
  type        = string
  default     = null
}

variable "alb_internal_certificate_arn" {
  description = "ACM certificate ARN used by the HTTPS listener on the internal ALB."
  type        = string
  default     = null
}

variable "albs" {
  description = "ALB definitions to merge with the module defaults (local.alb_default). Values in var.albs override defaults on key conflicts. Each ALB entry supports: create, internal, subnet_ids, idle_timeout, enable_http2, enable_deletion_protection, create_security_group, security_group_ids, security_group_ingress_rules, security_group_egress_rules, access_logs, and listeners."
  type        = map(any)
  default     = {}
}

variable "alb_idle_timeout" {
  description = "Default idle timeout (in seconds) for all ALBs. Can be overridden per ALB via var.albs."
  type        = number
  default     = 3600
}

variable "alb_enable_http2" {
  description = "Default HTTP/2 setting for all ALBs. Can be overridden per ALB via var.albs."
  type        = bool
  default     = false
}

variable "alb_enable_deletion_protection" {
  description = "Default deletion protection setting for all ALBs. Can be overridden per ALB via var.albs."
  type        = bool
  default     = false
}

variable "alb_access_logs" {
  description = "Default access logs configuration for all ALBs. Can be overridden per ALB via var.albs."
  type = object({
    bucket  = string
    enabled = optional(bool, true)
    prefix  = optional(string, null)
  })
  default = {
    bucket  = "central-alb-logs-123456789012-us-east-1"
    enabled = true
    prefix  = null
  }
}

variable "create_ssm_jumpbox" {
  description = "Feature flag to enable or disable the creation of the SSM jumpbox resources."
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