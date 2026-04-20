module "ssm_jumpbox" {
  source                          = "./modules/vpc/ssm-jumpbox"
  resource_prefix                 = var.resource_prefix
  vpc_id                          = module.vpc.vpc_id
  private_subnet_id               = module.vpc.private_subnets
  aws_service_base_security_group = var.create_vpc ? module.vpc-services[0].aws_service_base_security_group : null
  create_ssm_jumpbox              = var.create_ssm_jumpbox
  ssm_jumpbox_desired_capacity    = var.ssm_jumpbox_desired_capacity
  ssm_jumpbox_instance_type       = var.ssm_jumpbox_instance_type
}