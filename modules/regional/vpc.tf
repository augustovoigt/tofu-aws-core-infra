data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_count     = 3
  base_name    = var.resource_prefix
  vpc_cidr     = var.vpc_cidr
  has_vpc_cidr = try(length(trimspace(local.vpc_cidr)) > 0, false)

  azs = slice(data.aws_availability_zones.available.names, 0, local.az_count)

  total_24_subnets = 16
  all_24_subnets = local.has_vpc_cidr ? [
    for i in range(local.total_24_subnets) : cidrsubnet(local.vpc_cidr, 4, i)
  ] : []

  public_subnets  = local.has_vpc_cidr ? slice(local.all_24_subnets, 0, local.az_count) : []
  private_subnets = local.has_vpc_cidr ? slice(local.all_24_subnets, 6, 6 + local.az_count) : []

  database_base_24 = local.has_vpc_cidr ? local.all_24_subnets[12] : null
  database_subnets = local.has_vpc_cidr ? [
    for i in range(local.az_count) : cidrsubnet(local.database_base_24, 3, i)
  ] : []

  public_subnet_names   = [for az in local.azs : "public-subnet-application-1${substr(az, -1, 1)}"]
  private_subnet_names  = [for az in local.azs : "private-subnet-application-1${substr(az, -1, 1)}"]
  database_subnet_names = [for az in local.azs : "private-database-subnet-1${substr(az, -1, 1)}"]

  map_public_ip_on_launch = var.map_public_ip_on_launch

  common_tags = {
    OpenTofu  = "true"
    ManagedBy = "Platform Engineering Team"
  }

  vpc_tags = {
    Name = "${local.base_name}-vpc"
  }

  igw_tags = {
    Name = "${local.base_name}-igw"
  }

  public_route_table_tags = {
    Name = "${local.base_name}-rtb-public"
  }

  private_route_table_tags = {
    Name = "${local.base_name}-rtb-private"
  }

  nat_gateway_tags = var.single_nat_gateway ? { Name = "${local.base_name}-nat" } : {}
  nat_eip_tags     = var.single_nat_gateway ? { Name = "${local.base_name}-nat-eip" } : {}
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.0"

  create_vpc = var.create_vpc

  name = local.base_name
  cidr = local.has_vpc_cidr ? local.vpc_cidr : null

  azs = local.azs

  public_subnets          = local.public_subnets
  public_subnet_names     = local.public_subnet_names
  map_public_ip_on_launch = local.map_public_ip_on_launch

  private_subnets      = local.private_subnets
  private_subnet_names = local.private_subnet_names

  database_subnets      = local.database_subnets
  database_subnet_names = local.database_subnet_names

  create_database_subnet_group = var.create_database_subnet_group

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  create_igw = var.create_igw

  vpc_tags                 = local.vpc_tags
  igw_tags                 = local.igw_tags
  public_route_table_tags  = local.public_route_table_tags
  private_route_table_tags = local.private_route_table_tags
  nat_gateway_tags         = local.nat_gateway_tags
  nat_eip_tags             = local.nat_eip_tags

  tags = local.common_tags
}

module "vpc_gateway_endpoints" {
  count = var.create_vpc ? 1 : 0

  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "6.6.0"

  vpc_id = module.vpc.vpc_id
  endpoints = {
    for service in var.gateway_endpoints :
    service => {
      service         = service
      service_type    = "Gateway"
      route_table_ids = concat(module.vpc.private_route_table_ids, module.vpc.database_route_table_ids)
      tags            = { Name = "${local.base_name}-${service}-endpoint" }
    }
  }
}

module "vpc-services" {
  count             = var.create_vpc ? 1 : 0
  source            = "./modules/vpc/services"
  vpc_id            = module.vpc.vpc_id
  resource_prefix   = var.resource_prefix
  private_subnet_id = module.vpc.database_subnets
  public_subnet_id  = module.vpc.public_subnets
}