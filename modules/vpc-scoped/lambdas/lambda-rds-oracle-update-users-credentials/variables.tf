############################################################
# Lambda RDS Oracle Update Users Credentials - Variables  🇧🇷
############################################################

variable "aws_account_id" {
  description = "The AWS account ID where the Lambda function will be deployed"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix uniquely identifies Platform AWS resources. Needs to be unique per AWS (sub) account."
  type        = string
}

variable "create_lambda_function_iam_role" {
  description = "Enable or disable the creation of the IAM role for the Lambda function"
  type        = bool
  default     = false
}

variable "create_lambda_function" {
  description = "Enable or disable the creation of the Lambda function"
  type        = bool
  default     = false
}

variable "create" {
  description = "Master switch to create this lambda (function and IAM role). When set, it overrides create_lambda_function and create_lambda_function_iam_role."
  type        = bool
  default     = null
}

variable "lambda_layers" {
  description = "List of AWS Lambda layer ARNs to attach to the function"
  type        = list(string)
}

variable "subnet_ids" {
  description = "List of subnet IDs where the Lambda function should be deployed"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to assign to the Lambda function within the VPC"
  type        = list(string)
}