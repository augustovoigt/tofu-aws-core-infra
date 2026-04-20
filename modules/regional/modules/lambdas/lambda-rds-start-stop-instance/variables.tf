############################################################
# Lambda RDS Start Stop Instance - Variables              🇧🇷
############################################################

variable "aws_account_id" {
  description = "The AWS account ID where the Lambda function will be deployed"
  type        = string
}

variable "aws_region" {
  description = "The AWS region where the Lambda function will be deployed"
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