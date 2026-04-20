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
  description = "IAM role definitions to merge with the module defaults (local.iam_default_roles). Values in var.iam_roles override defaults on key conflicts."
  type        = map(any)
  default     = {}
}