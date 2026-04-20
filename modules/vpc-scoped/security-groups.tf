# AWS Security Groups

data "aws_ec2_managed_prefix_list" "internal_ips" {
  count = var.create_sg_internal_ips ? 1 : 0
  name  = "internal-ips-prefix-list"
}

locals {
  sg_custom_ips_effective        = var.sg_custom_ips
  sg_internal_ips_list_effective = var.sg_internal_ips_list
  sg_external_ips_list_effective = var.sg_external_ips_list

  security_groups_default = {
    custom = {
      create          = var.create_sg_custom
      name            = "${var.resource_prefix}-sg-custom"
      use_name_prefix = false
      description     = "Allow connections from custom CIDR blocks."
      vpc_id          = var.vpc_id

      ingress_with_cidr_blocks = concat(
        local.sg_custom_ips_effective != "" ? flatten([
          for ip in split(",", local.sg_custom_ips_effective) : [
            {
              from_port   = 1521
              to_port     = 1521
              protocol    = "tcp"
              cidr_blocks = trimspace(ip)
              description = "Allow Oracle traffic on port 1521 from custom NAT IPs."
            },
            {
              from_port   = 3306
              to_port     = 3306
              protocol    = "tcp"
              cidr_blocks = trimspace(ip)
              description = "Allow MySQL traffic on port 3306 from custom NAT IPs."
            }
          ]
        ]) : []
      )

      egress_with_cidr_blocks = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = "0.0.0.0/0"
          description = "Allow all outbound traffic."
        }
      ]

      tags = {
        Name = "${var.resource_prefix}-sg-custom"
      }
    }

    internal = {
      create          = var.create_sg_internal_ips
      name            = "internal-ips"
      use_name_prefix = false
      description     = "Allow connections from internal managed prefix list."
      vpc_id          = var.vpc_id

      ingress_with_prefix_list_ids = var.create_sg_internal_ips ? [
        {
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          prefix_list_ids = data.aws_ec2_managed_prefix_list.internal_ips[0].id
          description     = "Allow all inbound traffic from internal managed prefix list."
        }
      ] : []

      ingress_with_cidr_blocks = [
        for cidr in local.sg_internal_ips_list_effective : {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = cidr
          description = "Allow all inbound traffic from internal CIDR blocks."
        }
      ]

      egress_with_cidr_blocks = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = "0.0.0.0/0"
          description = "Allow all outbound traffic."
        }
      ]

      tags = {
        Name = "internal-ips"
      }

    }

    external = {
      create          = var.create_sg_external_ips
      name            = "external-ips"
      use_name_prefix = false
      description     = "Allow connections from external CIDR blocks."
      vpc_id          = var.vpc_id

      ingress_with_cidr_blocks = [
        for cidr in local.sg_external_ips_list_effective : {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = cidr
          description = "Allow all inbound traffic from external CIDR blocks."
        }
      ]

      egress_with_cidr_blocks = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = "0.0.0.0/0"
          description = "Allow all outbound traffic."
        }
      ]

      tags = {
        Name = "external-ips"
      }
    }
  }

  security_groups = merge(local.security_groups_default, var.security_groups)
}

module "security_groups" {
  source   = "terraform-aws-modules/security-group/aws"
  version  = "5.3.1"
  for_each = { for k, v in local.security_groups : k => v if try(v.create, true) }

  name            = each.value.name
  use_name_prefix = try(each.value.use_name_prefix, false)
  description     = try(each.value.description, null)
  vpc_id          = try(each.value.vpc_id, var.vpc_id)

  ingress_with_cidr_blocks     = try(each.value.ingress_with_cidr_blocks, [])
  ingress_with_prefix_list_ids = try(each.value.ingress_with_prefix_list_ids, [])
  egress_with_cidr_blocks      = try(each.value.egress_with_cidr_blocks, [])

  tags = try(each.value.tags, {})
}