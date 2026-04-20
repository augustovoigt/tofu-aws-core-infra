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

###################################################################
# VPC and Networking
###################################################################

variable "vpc_id" {
  description = "VPC ID where cluster resources are deployed."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must be a non-empty string."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used for VPC resources."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) > 0
    error_message = "private_subnet_ids must contain at least one subnet id."
  }

  validation {
    condition     = alltrue([for id in var.private_subnet_ids : length(trimspace(id)) > 0])
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
}

variable "elasticache_security_group_id" {
  description = "Security Group ID for Elasticache/Valkey."
  type        = string
}

variable "elasticache_subnet_group_name" {
  description = "Subnet group name for Elasticache/Valkey."
  type        = string
}

###################################################################
# EKS variables
###################################################################

variable "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN (used for IAM roles for service accounts)."
  type        = string
}

variable "eks_oidc_provider" {
  description = "EKS OIDC provider URL/identifier."
  type        = string
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

  validation {
    condition     = length(trimspace(var.apps_chart_version)) > 0
    error_message = "apps_chart_version must be a non-empty string."
  }
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

  validation {
    condition = alltrue([
      for o in var.sync_windows_ops : contains(["allow", "deny"], o.kind)
    ])
    error_message = "All sync_windows must have kind value of either allow or deny."
  }

  default = [
    /*     {
      kind         = "allow"
      schedule     = "0 12 * * *"
      duration     = "1h"
      timeZone     = ""
      manualSync   = true
      namespaces   = ["*"]
      clusters     = ["*"]
      applications = ["*"]
    }, */
  ]
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

  validation {
    condition = alltrue([
      for o in var.sync_windows_ops_customers : contains(["allow", "deny"], o.kind)
    ])
    error_message = "All sync_windows must have kind value of either allow or deny."
  }

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

  validation {
    condition = alltrue([
      for o in var.sync_windows_ops_internal : contains(["allow", "deny"], o.kind)
    ])
    error_message = "All sync_windows must have kind value of either allow or deny."
  }

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

  validation {
    condition     = contains(["prod", "dev"], var.addons_revision)
    error_message = "The addons_revision must be either 'prod' or 'dev'."
  }
  default = "dev"
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
  default     = ["platform-ops-argocd-infra", "platform-ops-charts"]

  validation {
    condition     = length(var.argocd_addons_repo_list_names) == length(distinct(var.argocd_addons_repo_list_names))
    error_message = "argocd_addons_repo_list_names must not contain duplicate values."
  }
}

variable "argocd_addons_repo_creds_app_id" {
  type        = string
  description = "Defines the Github App ID."
}

variable "argocd_addons_repo_creds_app_installation_id" {
  type        = string
  description = "Defines the Github installation ID."
}

variable "argocd_addons_repo_creds_private_key" {
  type        = string
  description = "Defines the Github private key."
  sensitive   = true
}

variable "create_argocd_repocreds" {
  description = "Whether to create ArgoCD repo-creds Secrets from the default repo list (argocd_addons_repo_list_names). Individual secrets can still be enabled/disabled via argocd_repocreds.*.create."
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
  description = "Whether to create Kubernetes PriorityClass resources from priority-classes.tf. When false, no PriorityClass resources are created."
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

variable "iam_roles" {
  description = "IAM role input overrides merged on top of local defaults in iam.tf. Use this to override name/policies/trust/permissions or to disable a role by setting create=false."
  type        = any
  default     = {}
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

variable "create_iam_role_cloudwatch_exporter" {
  description = "Create the IAM role used by the cloudwatch-exporter service account."
  type        = bool
  default     = true
}

variable "create_iam_role_prometheus_rds_exporter" {
  description = "Create the IAM role used by the prometheus-rds-exporter service account."
  type        = bool
  default     = false
}

variable "create_iam_role_finops_cronjob" {
  description = "Create the IAM role used by the finops cronjob service account."
  type        = bool
  default     = false
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
# Lambdas Layers
###################################################################

variable "lambda_layer_request_arn" {
  description = "ARN of the regional Lambda layer: request."
  type        = string

  validation {
    condition     = length(trimspace(var.lambda_layer_request_arn)) > 0
    error_message = "lambda_layer_request_arn must be a non-empty string."
  }
}

variable "lambda_layer_tabulate_arn" {
  description = "ARN of the regional Lambda layer: tabulate."
  type        = string

  validation {
    condition     = length(trimspace(var.lambda_layer_tabulate_arn)) > 0
    error_message = "lambda_layer_tabulate_arn must be a non-empty string."
  }
}

variable "lambda_layer_valkey_client_arn" {
  description = "ARN of the regional Lambda layer: valkey-client."
  type        = string

  validation {
    condition     = length(trimspace(var.lambda_layer_valkey_client_arn)) > 0
    error_message = "lambda_layer_valkey_client_arn must be a non-empty string."
  }
}

variable "lambda_layer_oracledb_arn" {
  description = "ARN of the regional Lambda layer: oracledb."
  type        = string

  validation {
    condition     = length(trimspace(var.lambda_layer_oracledb_arn)) > 0
    error_message = "lambda_layer_oracledb_arn must be a non-empty string."
  }
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
# Lambdas Function ARNs (used by Step Functions)
###################################################################

variable "lambda_rds_create_snapshot_arn" {
  description = "Lambda Function ARN for regional lambda_rds_create_snapshot."
  type        = string

  validation {
    condition     = length(trimspace(var.lambda_rds_create_snapshot_arn)) > 0
    error_message = "lambda_rds_create_snapshot_arn must be a non-empty string."
  }
}

variable "lambda_rds_delete_instance_arn" {
  description = "Lambda Function ARN for regional lambda_rds_delete_instance."
  type        = string

  validation {
    condition     = length(trimspace(var.lambda_rds_delete_instance_arn)) > 0
    error_message = "lambda_rds_delete_instance_arn must be a non-empty string."
  }
}

variable "lambda_rds_restore_snapshot_arn" {
  description = "Lambda Function ARN for regional lambda_rds_restore_snapshot."
  type        = string

  validation {
    condition     = length(trimspace(var.lambda_rds_restore_snapshot_arn)) > 0
    error_message = "lambda_rds_restore_snapshot_arn must be a non-empty string."
  }
}

variable "lambda_rds_modify_instance_arn" {
  description = "Lambda Function ARN for regional lambda_rds_modify_instance."
  type        = string

  validation {
    condition     = length(trimspace(var.lambda_rds_modify_instance_arn)) > 0
    error_message = "lambda_rds_modify_instance_arn must be a non-empty string."
  }
}

variable "lambda_rds_delete_snapshot_arn" {
  description = "Lambda Function ARN for regional lambda_rds_delete_snapshot."
  type        = string

  validation {
    condition     = length(trimspace(var.lambda_rds_delete_snapshot_arn)) > 0
    error_message = "lambda_rds_delete_snapshot_arn must be a non-empty string."
  }
}

variable "lambda_rds_status_check_arn" {
  description = "Lambda Function ARN for regional lambda_rds_status_check."
  type        = string

  validation {
    condition     = length(trimspace(var.lambda_rds_status_check_arn)) > 0
    error_message = "lambda_rds_status_check_arn must be a non-empty string."
  }
}

variable "lambda_rds_modify_instance_version_update_arn" {
  description = "Lambda Function ARN for regional lambda_rds_modify_instance_version_update."
  type        = string

  validation {
    condition     = length(trimspace(var.lambda_rds_modify_instance_version_update_arn)) > 0
    error_message = "lambda_rds_modify_instance_version_update_arn must be a non-empty string."
  }
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
  description = "Comma-separated CIDR blocks allowed to reach Oracle (1521) and MySQL (3306) through sg-custom. Example: '192.168.0.1/32,192.168.0.2/32'."
  type        = string
  default     = ""

  validation {
    condition     = var.sg_custom_ips == "" || length(trimspace(var.sg_custom_ips)) > 0
    error_message = "sg_custom_ips must not be whitespace-only when provided."
  }
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
  description = "Additional CIDR blocks allowed as ingress (all protocols/ports). Example: ['192.168.0.1/32,192.168.0.2/32']."
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

  validation {
    condition     = length(trimspace(var.valkey_engine_version)) > 0
    error_message = "valkey_engine_version must be a non-empty string."
  }
}

variable "valkey_node_type" {
  description = "ElastiCache node type for Valkey (e.g., cache.t4g.small)."
  type        = string
  default     = "cache.t3.small"

  validation {
    condition     = length(trimspace(var.valkey_node_type)) > 0
    error_message = "valkey_node_type must be a non-empty string."
  }
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

  validation {
    condition     = length(trimspace(var.valkey_maintenance_window)) > 0
    error_message = "valkey_maintenance_window must be a non-empty string."
  }
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
    min = 4096
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
    min = 2
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
    min = 4096
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
    min = 2
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
  default     = true
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