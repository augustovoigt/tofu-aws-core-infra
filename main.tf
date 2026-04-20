module "global" {
  count  = var.context == "global" ? 1 : 0
  source = "./modules/global"

  aws_region      = var.aws_region
  aws_account_id  = var.aws_account_id
  resource_prefix = var.resource_prefix

  create_iam_role_eventbridge_scheduler   = var.create_iam_role_eventbridge_scheduler
  create_iam_role_rds_enhanced_monitoring = var.create_iam_role_rds_enhanced_monitoring
  create_iam_role_rds_s3_integration      = var.create_iam_role_rds_s3_integration
  create_iam_role_cross_account_finops    = var.create_iam_role_cross_account_finops

  iam_roles = var.iam_roles
}

module "regional" {
  count  = var.context == "regional" ? 1 : 0
  source = "./modules/regional"

  aws_region      = var.aws_region
  aws_account_id  = var.aws_account_id
  resource_prefix = var.resource_prefix

  create_s3  = var.create_s3
  s3_buckets = var.s3_buckets

  create_rds_option_groups    = var.create_rds_option_groups
  create_rds_parameter_groups = var.create_rds_parameter_groups
  rds_option_groups           = var.rds_option_groups
  rds_parameter_groups        = var.rds_parameter_groups

  create_waf = var.create_waf
  waf        = var.waf

  create_secrets_manager               = var.create_secrets_manager
  app_env_secrets                      = var.app_env_secrets
  iam_role_rds_enhanced_monitoring_arn = var.iam_role_rds_enhanced_monitoring_arn
  iam_role_rds_s3_integration_arn      = var.iam_role_rds_s3_integration_arn

  create_lambda_rds_delete_instance                = var.create_lambda_rds_delete_instance
  create_lambda_rds_modify_instance                = var.create_lambda_rds_modify_instance
  create_lambda_rds_create_snapshot                = var.create_lambda_rds_create_snapshot
  create_lambda_rds_delete_snapshot                = var.create_lambda_rds_delete_snapshot
  create_lambda_rds_restore_snapshot               = var.create_lambda_rds_restore_snapshot
  create_lambda_rds_start_stop_instance            = var.create_lambda_rds_start_stop_instance
  create_lambda_rds_status_check                   = var.create_lambda_rds_status_check
  create_lambda_rds_modify_instance_version_update = var.create_lambda_rds_modify_instance_version_update

  create_layer_request       = var.create_layer_request
  create_layer_tabulate      = var.create_layer_tabulate
  create_layer_valkey_client = var.create_layer_valkey_client
  create_layer_oracledb      = var.create_layer_oracledb
  create_layer_mysqldb       = var.create_layer_mysqldb
  create_layer_cryptography  = var.create_layer_cryptography

  create_sns_topic                  = var.create_sns_topic
  sns_topic_name                    = var.sns_topic_name
  sns_topic_subscription_email      = var.sns_topic_subscription_email
  sns_topic_subscriptions           = var.sns_topic_subscriptions
  sns_topic_arn_override            = var.sns_topic_arn_override
  enable_kms_disabled_alert         = var.enable_kms_disabled_alert
  enable_kms_deletion_alert         = var.enable_kms_deletion_alert
  eventbridge_role_name             = var.eventbridge_role_name
  notifications_eventbridge_rules   = var.notifications_eventbridge_rules
  notifications_eventbridge_targets = var.notifications_eventbridge_targets

  create_vpc                   = var.create_vpc
  vpc_cidr                     = var.vpc_cidr
  create_database_subnet_group = var.create_database_subnet_group
  enable_nat_gateway           = var.enable_nat_gateway
  single_nat_gateway           = var.single_nat_gateway
  one_nat_gateway_per_az       = var.one_nat_gateway_per_az
  create_igw                   = var.create_igw
  map_public_ip_on_launch      = var.map_public_ip_on_launch
  gateway_endpoints            = var.gateway_endpoints

  create_ssm_jumpbox           = var.create_ssm_jumpbox
  ssm_jumpbox_desired_capacity = var.ssm_jumpbox_desired_capacity
  ssm_jumpbox_instance_type    = var.ssm_jumpbox_instance_type
}

module "vpc_scoped" {
  count  = var.context == "vpc-scoped" ? 1 : 0
  source = "./modules/vpc-scoped"

  aws_region      = var.aws_region
  aws_account_id  = var.aws_account_id
  resource_prefix = var.resource_prefix

  vpc_id                             = var.vpc_id
  private_subnet_ids                 = var.private_subnet_ids
  aws_service_base_security_group_id = var.aws_service_base_security_group_id
  elasticache_security_group_id      = var.elasticache_security_group_id
  elasticache_subnet_group_name      = var.elasticache_subnet_group_name
  eks_oidc_provider_arn              = var.eks_oidc_provider_arn
  eks_oidc_provider                  = var.eks_oidc_provider

  apps_chart_version         = var.apps_chart_version
  sync_windows_ops           = var.sync_windows_ops
  sync_windows_ops_customers = var.sync_windows_ops_customers
  sync_windows_ops_internal  = var.sync_windows_ops_internal

  create_argocd_apps                      = var.create_argocd_apps
  addons_enable                           = var.addons_enable
  addons_revision                         = var.addons_revision
  addons_crossplane_providers             = var.addons_crossplane_providers
  addons_enable_github_runners            = var.addons_enable_github_runners
  addons_enable_kubernetes_event_exporter = var.addons_enable_kubernetes_event_exporter
  addons_enable_monitoring                = var.addons_enable_monitoring
  addons_enable_stakater_reloader         = var.addons_enable_stakater_reloader
  addons_enable_pci_addons                = var.addons_enable_pci_addons
  addons_enable_pci_addons_patches        = var.addons_enable_pci_addons_patches
  addons_enable_pci_addons_efs_csi_driver = var.addons_enable_pci_addons_efs_csi_driver
  customers_revision                      = var.customers_revision
  internal_revision                       = var.internal_revision

  argocd_addons_repo_list_names                = var.argocd_addons_repo_list_names
  argocd_addons_repo_creds_app_id              = var.argocd_addons_repo_creds_app_id
  argocd_addons_repo_creds_app_installation_id = var.argocd_addons_repo_creds_app_installation_id
  argocd_addons_repo_creds_private_key         = var.argocd_addons_repo_creds_private_key
  create_argocd_repocreds                      = var.create_argocd_repocreds
  argocd_repocreds                             = var.argocd_repocreds

  create_iam_role_cloudwatch_exporter           = var.create_iam_role_cloudwatch_exporter
  create_iam_role_prometheus_rds_exporter       = var.create_iam_role_prometheus_rds_exporter
  create_iam_role_finops_cronjob                = var.create_iam_role_finops_cronjob
  create_iam_role_step_functions_dump_rds       = var.create_iam_role_step_functions_dump_rds
  create_iam_role_step_functions_version_update = var.create_iam_role_step_functions_version_update
  iam_roles                                     = var.iam_roles

  create_step_function_dump_rds       = var.create_step_function_dump_rds
  create_step_function_version_update = var.create_step_function_version_update
  step_functions                      = var.step_functions

  lambda_layer_request_arn       = var.lambda_layer_request_arn
  lambda_layer_tabulate_arn      = var.lambda_layer_tabulate_arn
  lambda_layer_valkey_client_arn = var.lambda_layer_valkey_client_arn
  lambda_layer_oracledb_arn      = var.lambda_layer_oracledb_arn
  lambda_layer_mysqldb_arn       = var.lambda_layer_mysqldb_arn
  lambda_layer_cryptography_arn  = var.lambda_layer_cryptography_arn

  lambda_rds_create_snapshot_arn                = var.lambda_rds_create_snapshot_arn
  lambda_rds_delete_instance_arn                = var.lambda_rds_delete_instance_arn
  lambda_rds_restore_snapshot_arn               = var.lambda_rds_restore_snapshot_arn
  lambda_rds_modify_instance_arn                = var.lambda_rds_modify_instance_arn
  lambda_rds_delete_snapshot_arn                = var.lambda_rds_delete_snapshot_arn
  lambda_rds_status_check_arn                   = var.lambda_rds_status_check_arn
  lambda_rds_modify_instance_version_update_arn = var.lambda_rds_modify_instance_version_update_arn

  create_lambda_rds_oracle_execute_sql_statements           = var.create_lambda_rds_oracle_execute_sql_statements
  create_lambda_rds_oracle_update_users_credentials         = var.create_lambda_rds_oracle_update_users_credentials
  create_lambda_valkey_clear_cache                          = var.create_lambda_valkey_clear_cache
  create_lambda_secretsmanager_rds_oracle_password_rotation = var.create_lambda_secretsmanager_rds_oracle_password_rotation
  create_lambda_secretsmanager_rds_mysql_password_rotation  = var.create_lambda_secretsmanager_rds_mysql_password_rotation

  nodepools             = var.nodepools
  create_nodepool       = var.create_nodepool
  create_priority_class = var.create_priority_class
  priority_classes      = var.priority_classes
  namespaces            = var.namespaces

  create_namespace_platform_ops_internal  = var.create_namespace_platform_ops_internal
  create_namespace_platform_ops_customers = var.create_namespace_platform_ops_customers
  create_namespace_platform_ops_addons    = var.create_namespace_platform_ops_addons
  create_namespace_platform_ops           = var.create_namespace_platform_ops

  create_sg_custom       = var.create_sg_custom
  sg_custom_ips          = var.sg_custom_ips
  security_groups        = var.security_groups
  create_sg_internal_ips = var.create_sg_internal_ips
  sg_internal_ips_list   = var.sg_internal_ips_list
  create_sg_external_ips = var.create_sg_external_ips
  sg_external_ips_list   = var.sg_external_ips_list

  create_valkey                = var.create_valkey
  create_valkey_security_group = var.create_valkey_security_group
  create_valkey_subnet_group   = var.create_valkey_subnet_group
  valkey_engine_version        = var.valkey_engine_version
  valkey_node_type             = var.valkey_node_type
  valkey_multi_az              = var.valkey_multi_az
  valkey_maintenance_window    = var.valkey_maintenance_window
  valkeys                      = var.valkeys

  create_ecs_cluster               = var.create_ecs_cluster
  ecs_mi_on_demand_memory_mib      = var.ecs_mi_on_demand_memory_mib
  ecs_mi_on_demand_vcpu_count      = var.ecs_mi_on_demand_vcpu_count
  ecs_mi_spot_memory_mib           = var.ecs_mi_spot_memory_mib
  ecs_mi_spot_vcpu_count           = var.ecs_mi_spot_vcpu_count
  ecs_mi_storage_size_gib          = var.ecs_mi_storage_size_gib
  ecs_mi_spot_max_price_percentage = var.ecs_mi_spot_max_price_percentage
  ecs_ingress_rules                = var.ecs_ingress_rules
  ecs_create_cloud_map_namespace   = var.ecs_create_cloud_map_namespace
  ecs_cloud_map_namespace_name     = var.ecs_cloud_map_namespace_name

  public_subnet_ids              = var.public_subnet_ids
  create_alb_public              = var.create_alb_public
  create_alb_internal            = var.create_alb_internal
  alb_public_certificate_arn     = var.alb_public_certificate_arn
  alb_internal_certificate_arn   = var.alb_internal_certificate_arn
  albs                           = var.albs
  alb_idle_timeout               = var.alb_idle_timeout
  alb_enable_http2               = var.alb_enable_http2
  alb_enable_deletion_protection = var.alb_enable_deletion_protection
  alb_access_logs                = var.alb_access_logs
}