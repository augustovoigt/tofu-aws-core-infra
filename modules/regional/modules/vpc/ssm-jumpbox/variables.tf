variable "create_ssm_jumpbox" {
  description = "Feature flag to enable or disable the creation of all ssm-jumpbox resources."
  type        = bool
  default     = false
}

variable "resource_prefix" {
  description = "Prefix uniquely identifies AWS resources. Needs to be unique per AWS (sub) account."
  type        = string
}

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

variable "aws_service_base_security_group" {
  description = "The security group to use as a source for the ssm-jumpbox host."
  type = object({
    id = string
  })
  default = null
}

variable "ssm_jumpbox_instance_type" {
  description = "The ec2 instance type for the ssm-jumpbox host."
  type        = string
  default     = "t4g.micro"
}

variable "ssm_jumpbox_desired_capacity" {
  description = "Desired number of ssm-jumpbox instances. Set to 1 to launch, 0 to terminate."
  type        = number
  default     = 1
}

variable "ami_id" {
  description = "The AMI ID to use for the ssm-jumpbox host."
  type        = string
  default     = ""
}