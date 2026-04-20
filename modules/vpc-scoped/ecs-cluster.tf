# ECS Cluster Locals

locals {
  cluster_name                = var.resource_prefix
  cloud_map_namespace_enabled = var.create_ecs_cluster && var.ecs_create_cloud_map_namespace
  cloud_map_namespace_name    = coalesce(var.ecs_cloud_map_namespace_name, "${var.resource_prefix}.local")

  service_connect_defaults = local.cloud_map_namespace_enabled ? {
    namespace = aws_service_discovery_private_dns_namespace.ecs_cluster[0].arn
  } : null

  capacity_providers = var.create_ecs_cluster ? {
    on_demand = {
      managed_instances_provider = {
        instance_launch_template = {
          capacity_option_type = "ON_DEMAND"
          instance_requirements = {
            instance_generations = ["current"]
            cpu_manufacturers    = ["intel", "amd"]

            memory_mib = {
              min = var.ecs_mi_on_demand_memory_mib.min
              max = var.ecs_mi_on_demand_memory_mib.max
            }

            vcpu_count = {
              min = var.ecs_mi_on_demand_vcpu_count.min
              max = var.ecs_mi_on_demand_vcpu_count.max
            }
          }

          network_configuration = {
            subnets = var.private_subnet_ids
          }

          storage_configuration = {
            storage_size_gib = var.ecs_mi_storage_size_gib
          }
        }
      }
    }
    spot = {
      managed_instances_provider = {
        instance_launch_template = {
          capacity_option_type = "SPOT"

          instance_requirements = {
            instance_generations = ["current"]
            cpu_manufacturers    = ["intel", "amd"]

            memory_mib = {
              min = var.ecs_mi_spot_memory_mib.min
              max = var.ecs_mi_spot_memory_mib.max
            }

            vcpu_count = {
              min = var.ecs_mi_spot_vcpu_count.min
              max = var.ecs_mi_spot_vcpu_count.max
            }

            spot_max_price_percentage_over_lowest_price = var.ecs_mi_spot_max_price_percentage
          }

          network_configuration = {
            subnets = var.private_subnet_ids
          }

          storage_configuration = {
            storage_size_gib = var.ecs_mi_storage_size_gib
          }
        }
      }
    }
  } : null

  default_capacity_provider_strategy = var.create_ecs_cluster ? {
    on_demand = {
      weight = 1
      base   = 1
    }
    spot = {
      weight = 2
    }
  } : null
}

# Cloud Map (private namespace for ECS Service Connect)

resource "aws_service_discovery_private_dns_namespace" "ecs_cluster" {
  count = local.cloud_map_namespace_enabled ? 1 : 0

  name        = local.cloud_map_namespace_name
  description = "Private DNS namespace for ECS cluster ${local.cluster_name}"
  vpc         = var.vpc_id
}

# ECS Cluster (Managed Instances)

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "7.5.0"

  create = var.create_ecs_cluster
  name   = local.cluster_name

  service_connect_defaults = local.service_connect_defaults

  default_capacity_provider_strategy = local.default_capacity_provider_strategy

  capacity_providers = local.capacity_providers

  # Managed instances security group
  vpc_id = var.vpc_id

  security_group_ingress_rules = {
    for i, rule in var.ecs_ingress_rules : "custom_${i}" => {
      from_port   = rule.port
      to_port     = rule.port
      ip_protocol = "tcp"
      cidr_ipv4   = rule.cidr
    }
  }

  security_group_egress_rules = {
    all = {
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "-1"
    }
  }

  tags = {
    Name = local.cluster_name
  }
}
