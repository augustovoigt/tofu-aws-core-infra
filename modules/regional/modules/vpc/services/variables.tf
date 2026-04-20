variable "vpc_id" {
  description = "VPC ID where cluster resources are deployed."
  type        = string
  default     = null
}

variable "private_subnet_id" {
  description = "List of private subnet IDs to use for cluster resources."
  type        = list(string)
  default     = []
}

variable "public_subnet_id" {
  description = "List of public subnet IDs to use for cluster resources."
  type        = list(string)
  default     = []
}

variable "base_security_group_tags" {
  description = "Tags for the base security group."
  type        = map(string)
  default     = {}
}

variable "resource_prefix" {
  description = "Resource prefix for AWS Core resources. Needs to be unique per AWS (sub) account."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_prefix)) > 0
    error_message = "resource_prefix must be a non-empty string."
  }
}