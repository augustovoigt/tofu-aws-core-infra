# tofu-aws-core-infra

OpenTofu module for provisioning the **core infrastructure** of a multi-account AWS platform. Supports both EKS and ECS deployment models through feature flags and a context-based architecture.

This module acts as a **root wrapper** that deploys exactly one of the core-infra contexts per run via a single input: `context`. It also serves as a centralized module catalog (the submodules under `./modules/`) consumed by the infrastructure layer (`tofu-aws-infra`) and shared by application deployments in both EKS and ECS contexts.

## What this module creates

### Global context (`context = "global"`)

Runs once per AWS account.

| Resource | Description | Feature flag |
|---|---|---|
| **IAM Role — EventBridge Scheduler** | Role for EventBridge Scheduler to invoke Lambdas and Step Functions | `create_iam_role_eventbridge_scheduler` |
| **IAM Role — RDS Enhanced Monitoring** | Monitoring role for RDS instances | `create_iam_role_rds_enhanced_monitoring` |
| **IAM Role — RDS S3 Integration** | Role for RDS to export/backup to S3 | `create_iam_role_rds_s3_integration` |
| **IAM Role — Cross-Account FinOps** | Read-only role for FinOps AWS account | `create_iam_role_cross_account_finops` |

### Regional context (`context = "regional"`)

Runs once per AWS account + region.

| Resource | Description | Feature flag |
|---|---|---|
| **VPC** | Network foundation with public, private, and database subnets, NAT/IGW | `create_vpc` |
| **S3 Buckets** | Temporary storage for Lambda layers and user-defined buckets | `create_s3` |
| **RDS Option Groups** | Pre-configured for Oracle SE2 19 (timezone, JVM, S3 integration) | `create_rds_option_groups` |
| **RDS Parameter Groups** | Tuned for Oracle SE2 19 per instance class (t3.medium/large/xlarge) | `create_rds_parameter_groups` |
| **Secrets Manager** | AppServer environment secrets | `create_secrets_manager` |
| **Lambda Functions (8)** | RDS operations: create/delete/restore snapshot, start/stop, modify, status check, version update | `create_lambda_rds_*` |
| **Lambda Layers (6)** | Shared libraries: oracledb, mysqldb, request, tabulate, valkey-client, cryptography | `create_layer_*` |
| **WAF** | Web ACL with AWS Managed Rules (SQLi, bad inputs, admin protection) | `create_waf` |
| **SNS Notifications** | Platform alert topic with email subscriptions and KMS event rules | `create_sns_topic`, `enable_kms_*_alert` |
| **SSM Jumpbox** | Auto Scaling Group for bastion instances with Session Manager access | `create_ssm_jumpbox` |

### VPC-Scoped context (`context = "vpc-scoped"`)

Runs once per VPC (EKS cluster or ECS environment).

| Resource | Description | Feature flag |
|---|---|---|
| **Valkey (ElastiCache)** | Redis-compatible cache cluster with encryption and Multi-AZ | `create_valkey` |
| **ECS Cluster** | Cluster with ON_DEMAND and SPOT capacity providers (managed instances) | `create_ecs_cluster` |
| **Cloud Map Namespace** | Private DNS for ECS Service Connect | `ecs_create_cloud_map_namespace` |
| **ALB (Public)** | Internet-facing load balancer with HTTPS listener | `create_alb_public` |
| **ALB (Internal)** | Internal load balancer with HTTPS listener | `create_alb_internal` |
| **Security Groups** | Internal IPs, external IPs, and custom SGs | `create_sg_internal_ips`, `create_sg_external_ips`, `create_sg_custom` |
| **Lambda Functions (5)** | Oracle SQL execution, user credential updates, Valkey cache clear, Secrets Manager rotation (Oracle/MySQL) | `create_lambda_rds_oracle_*`, `create_lambda_valkey_*`, `create_lambda_secretsmanager_*` |
| **Step Functions** | RDS dump and version update state machines | `create_step_function_dump_rds`, `create_step_function_version_update` |
| **IAM Roles** | CloudWatch exporter, Prometheus RDS exporter, FinOps cronjob (IRSA) | `create_iam_role_cloudwatch_exporter`, `create_iam_role_prometheus_rds_exporter`, `create_iam_role_finops_cronjob` |
| **Kubernetes Namespaces** | platform-ops, addons, customers, internal | `create_namespace_platform_ops*` |
| **Karpenter NodePools** | Auto-scaling node pools for EKS | `create_nodepool` |
| **PriorityClasses** | top-priority, secrets-objects, prod, nonprod | `create_priority_class` |
| **ArgoCD Apps & Repo Creds** | Projects, applications, and GitHub repo credentials | `create_argocd_apps`, `create_argocd_repocreds` |
| **ArgoCD Addons** | Monitoring, GitHub Runners, PCI, Reloader, Event Exporter | `addons_enable`, `addons_enable_*` |

## How it works

### Context-based architecture

The module is split into three **contexts** — `global`, `regional`, and `vpc-scoped` — each mapping to a separate OpenTofu state in the caller repo (`tofu-aws-infra`). This design enables independent lifecycle management at each scope:

| State | Context | Scope | Frequency |
|---|---|---|---|
| `core-global` | `context = "global"` | AWS account | **1×** per account |
| `core-regional` | `context = "regional"` | AWS account + region | **1×** per region |
| `core-vpc-scoped` | `context = "vpc-scoped"` | VPC / EKS cluster | **1×** per VPC |

**Why separate states?**

- **Global** resources (IAM roles, cross-account policies) are created **once per account** and never change when you expand to new regions or VPCs. Isolating them avoids unnecessary plan/apply cycles.
- **Regional** resources (VPC, RDS parameter groups, Lambda layers, WAF) are provisioned **once per region**. When scaling to multi-region, you add a new `core-regional` state per region without touching the global or VPC-scoped states.
- **VPC-scoped** resources (ECS cluster, ALBs, security groups, Kubernetes namespaces, ArgoCD apps) live inside a specific VPC. Running multiple VPCs (e.g., prod + staging, or multi-cluster) means separate `core-vpc-scoped` states that can be planned and applied independently.

This separation keeps blast radius small, plan times fast, and allows parallel execution across contexts.

### Feature flags

Resource creation is controlled via **feature flags** (`create_*` variables) and the `context` selector, allowing the same module to serve both EKS and ECS deployments.

## Submodules

Each context is also available as a standalone submodule:

| Submodule | Path | README |
|---|---|---|
| Global | `modules/global` | [README](modules/global/README.md) |
| Regional | `modules/regional` | [README](modules/regional/README.md) |
| VPC-Scoped | `modules/vpc-scoped` | [README](modules/vpc-scoped/README.md) |

## Example usage

The snippets below illustrate inputs for each context. In real usage, wire inputs from data sources, locals, or pipeline variables.

## EKS

### EKS - Global (once per account)

Creates account-level IAM roles shared by all regional and VPC-scoped contexts.

```hcl
module "core" {
	# Prefer pinning to a tag/commit.
	source = "git::https://github.com/augustovoigt/tofu-aws-core-infra.git?ref=<tag-or-commit>"

	context = "global"

	# General
	aws_region      = var.aws_region
	aws_account_id  = var.aws_account_id
	resource_prefix = var.resource_prefix

	# IAM
	create_iam_role_eventbridge_scheduler   = true
	create_iam_role_rds_enhanced_monitoring = true
	create_iam_role_rds_s3_integration      = true
}
```

### EKS - Regional (once per account + region)

Creates S3 buckets, RDS option/parameter groups, Lambda functions and layers, WAF, SNS notifications, Secrets Manager, and Kubernetes namespaces.

```hcl
module "core" {
	source = "git::https://github.com/augustovoigt/tofu-aws-core-infra.git?ref=<tag-or-commit>"

	context = "regional"

	# General
	aws_region      = var.aws_region
	aws_account_id  = var.aws_account_id
	resource_prefix = var.resource_prefix

	# IAM roles are created by the global context and passed into the regional context
	create_iam_role_prometheus_rds_exporter = true
	iam_role_rds_enhanced_monitoring_arn = local.global_outputs.core.iam_roles.rds_enhanced_monitoring.arn
	iam_role_rds_s3_integration_arn      = local.global_outputs.core.iam_roles.rds_s3_integration.arn

	# S3
	create_s3               = true
	create_s3_platform_temp = true

	# RDS
	create_rds_option_groups    = true
	create_rds_parameter_groups = true

	# Secrets Manager
	create_secrets_manager = true

	# WAF
	create_waf = true

	# Notifications
	create_sns_topic             = true
	sns_topic_subscription_email = "platform-ops@example.com"

	# KMS alerts (adds default EventBridge rule+target)
	enable_kms_disabled_alert = true
	enable_kms_deletion_alert = true

	# Namespaces
	create_namespace_platform_ops           = true
	create_namespace_platform_ops_addons    = true
	create_namespace_platform_ops_customers = true
	create_namespace_platform_ops_internal  = true
}
```

### EKS - VPC Scoped (once per VPC)

Creates Valkey (ElastiCache), VPC-scoped Lambdas and Step Functions, IAM roles (IRSA), Kubernetes namespaces, Karpenter NodePools, PriorityClasses, and ArgoCD applications/repo credentials.

```hcl
module "core" {
	source = "git::https://github.com/augustovoigt/tofu-aws-core-infra.git?ref=<tag-or-commit>"

	context = "vpc-scoped"

	# General
	aws_region      = var.aws_region
	aws_account_id  = var.aws_account_id
	resource_prefix = var.resource_prefix

	# VPC
	vpc_id                             = local.regional_outputs.core.vpc_id
	aws_service_base_security_group_id = local.regional_outputs.core.aws_service_base_security_group.id
	private_subnet_ids                 = local.regional_outputs.core.private_subnets

	# Elasticache
	elasticache_security_group_id = module.get_platform_states.vpc.primary_vpc.security_groups.elasticache.id
	elasticache_subnet_group_name = module.get_platform_states.vpc.primary_vpc.subnet_groups.elasticache.name

	# EKS
	eks_oidc_provider_arn = module.get_platform_states.eks.oidc.provider_arn
	eks_oidc_provider     = module.get_platform_states.eks.eks.oidc_provider

	# ArgoCD
	create_argocd_repocreds                      = true
	create_argocd_apps                           = true
	argocd_addons_repo_creds_app_id              = "123456"
	argocd_addons_repo_creds_app_installation_id = "9876543"
	argocd_addons_repo_creds_private_key         = "-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----"

	# Lambdas ARNs
	lambda_rds_create_snapshot_arn                = local.regional_outputs.core.lambda_rds_create_snapshot.lambda_rds_create_snapshot.lambda_function_arn
	lambda_rds_delete_instance_arn                = local.regional_outputs.core.lambda_rds_delete_instance.lambda_rds_delete_instance.lambda_function_arn
	lambda_rds_restore_snapshot_arn               = local.regional_outputs.core.lambda_rds_restore_snapshot.lambda_rds_restore_snapshot.lambda_function_arn
	lambda_rds_modify_instance_arn                = local.regional_outputs.core.lambda_rds_modify_instance.lambda_rds_modify_instance.lambda_function_arn
	lambda_rds_delete_snapshot_arn                = local.regional_outputs.core.lambda_rds_delete_snapshot.lambda_rds_delete_snapshot.lambda_function_arn
	lambda_rds_status_check_arn                   = local.regional_outputs.core.lambda_rds_status_check.lambda_rds_status_check.lambda_function_arn
	lambda_rds_modify_instance_version_update_arn = local.regional_outputs.core.lambda_rds_modify_instance_version_update.lambda_rds_modify_instance_version_update.lambda_function_arn

	lambda_layer_oracledb_arn      = local.regional_outputs.core.layer_oracledb.layer_oracledb.lambda_layer_arn
	lambda_layer_tabulate_arn      = local.regional_outputs.core.layer_tabulate.layer_tabulate.lambda_layer_arn
	lambda_layer_valkey_client_arn = local.regional_outputs.core.layer_valkey_client.layer_valkey_client.lambda_layer_arn
	lambda_layer_request_arn       = local.regional_outputs.core.layer_request.layer_request.lambda_layer_arn

	# Kubernetes - namespaces
	create_namespace_platform_ops           = true
	create_namespace_platform_ops_addons    = true
	create_namespace_platform_ops_customers = true
	create_namespace_platform_ops_internal  = true

	# Kubernetes - nodepool
	create_nodepool = true

	# Kubernetes - priority class
	create_priority_class = true

	# IAM
	create_iam_role_cloudwatch_exporter           = true
	create_iam_role_prometheus_rds_exporter       = true
}
```

## ECS

### ECS - Global (once per account)

Same as the EKS global context — creates account-level IAM roles.

```hcl
module "core" {
	# Prefer pinning to a tag/commit.
	source = "git::https://github.com/augustovoigt/tofu-aws-core-infra.git?ref=<tag-or-commit>"

	context = "global"

	# General
	aws_region      = var.aws_region
	aws_account_id  = var.aws_account_id
	resource_prefix = var.resource_prefix

	# IAM
	create_iam_role_eventbridge_scheduler   = true
	create_iam_role_rds_enhanced_monitoring = true
	create_iam_role_rds_s3_integration      = true
}
```

### ECS - Regional (once per account + region)

Same as the EKS regional context but also creates the VPC, SSM jumpbox, and omits Kubernetes namespaces (those are EKS-only).

```hcl
module "core" {
	source = "git::https://github.com/augustovoigt/tofu-aws-core-infra.git?ref=<tag-or-commit>"

	context = "regional"

	# General
	aws_region      = var.aws_region
	aws_account_id  = var.aws_account_id
	resource_prefix = var.resource_prefix

	# IAM roles are created by the global context and passed into the regional context
	iam_role_rds_enhanced_monitoring_arn = local.global_outputs.core.iam_roles.rds_enhanced_monitoring.arn
	iam_role_rds_s3_integration_arn      = local.global_outputs.core.iam_roles.rds_s3_integration.arn

	# S3
	create_s3               = true
	create_s3_platform_temp = true

	# RDS
	create_rds_option_groups    = true
	create_rds_parameter_groups = true

	# Secrets Manager
	create_secrets_manager = true

	# WAF
	create_waf = true

	# Notifications
	create_sns_topic             = true
	sns_topic_subscription_email = "platform-ops@example.com"

	# KMS alerts (adds default EventBridge rule+target)
	enable_kms_disabled_alert = true
	enable_kms_deletion_alert = true

	# VPC
	create_vpc              = true
	vpc_cidr                = "10.80.176.0/20"
	enable_nat_gateway      = true
	single_nat_gateway      = true
	create_igw              = true
	map_public_ip_on_launch = true

	# SSM Jumpbox
	create_ssm_jumpbox = true
}
```

### ECS - VPC Scoped (once per VPC)

Creates ECS cluster with managed instances (ON_DEMAND + SPOT), Valkey, VPC-scoped Lambdas and Step Functions, security groups, and ALBs (public + internal). No Kubernetes resources.

```hcl
module "core" {
	source = "git::https://github.com/augustovoigt/tofu-aws-core-infra.git?ref=<tag-or-commit>"

	context = "vpc-scoped"

	# General
	aws_region      = var.aws_region
	aws_account_id  = var.aws_account_id
	resource_prefix = var.resource_prefix

  # VPC
  vpc_id                             = local.regional_outputs.core.vpc_id
  aws_service_base_security_group_id = local.regional_outputs.core.aws_service_base_security_group.id
  private_subnet_ids                 = local.regional_outputs.core.private_subnets
  public_subnet_ids                  = local.regional_outputs.core.public_subnets

  # Elasticache
  create_valkey_security_group = true
  create_valkey_subnet_group   = true

  # Lambdas ARNs
  lambda_rds_create_snapshot_arn                = local.regional_outputs.core.lambda_rds_create_snapshot.lambda_rds_create_snapshot.lambda_function_arn
  lambda_rds_delete_instance_arn                = local.regional_outputs.core.lambda_rds_delete_instance.lambda_rds_delete_instance.lambda_function_arn
  lambda_rds_restore_snapshot_arn               = local.regional_outputs.core.lambda_rds_restore_snapshot.lambda_rds_restore_snapshot.lambda_function_arn
  lambda_rds_modify_instance_arn                = local.regional_outputs.core.lambda_rds_modify_instance.lambda_rds_modify_instance.lambda_function_arn
  lambda_rds_delete_snapshot_arn                = local.regional_outputs.core.lambda_rds_delete_snapshot.lambda_rds_delete_snapshot.lambda_function_arn
  lambda_rds_status_check_arn                   = local.regional_outputs.core.lambda_rds_status_check.lambda_rds_status_check.lambda_function_arn
  lambda_rds_modify_instance_version_update_arn = local.regional_outputs.core.lambda_rds_modify_instance_version_update.lambda_rds_modify_instance_version_update.lambda_function_arn

  # Layers
  lambda_layer_oracledb_arn      = local.regional_outputs.core.layer_oracledb.layer_oracledb.lambda_layer_arn
  lambda_layer_tabulate_arn      = local.regional_outputs.core.layer_tabulate.layer_tabulate.lambda_layer_arn
  lambda_layer_valkey_client_arn = local.regional_outputs.core.layer_valkey_client.layer_valkey_client.lambda_layer_arn
  lambda_layer_request_arn       = local.regional_outputs.core.layer_request.layer_request.lambda_layer_arn

  create_lambda_secretsmanager_rds_oracle_password_rotation = false
  create_lambda_secretsmanager_rds_mysql_password_rotation  = false

	# ECS Cluster
	create_ecs_cluster             = true
	ecs_create_cloud_map_namespace = true

	# Security Groups
	create_sg_internal_ips = true
	sg_internal_ips_list   = ["10.0.0.0/8"]

	create_sg_external_ips = true
	sg_external_ips_list   = ["203.0.113.0/24", "198.51.100.0/24"]

	# Load Balancer (ALB)
	create_alb_public            	= true
	create_alb_internal          	= true
	alb_public_certificate_arn 	 	= local.global_outputs.route53_domain.public_zones[var.resource_prefix].acm_certificate_arn
	alb_internal_certificate_arn    = local.global_outputs.route53_domain.public_zones[var.resource_prefix].acm_certificate_arn

	# Optional: override ALB defaults (applies to all ALBs)
	# alb_idle_timeout               = 3600
	# alb_enable_http2               = false
	# alb_enable_deletion_protection = false
	# alb_access_logs = {
	#   bucket  = "my-alb-logs-bucket"
	#   enabled = true
	#   prefix  = null
	# }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.11 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.1.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | ~> 2.1.2 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 3.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.8.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_global"></a> [global](#module\_global) | ./modules/global | n/a |
| <a name="module_regional"></a> [regional](#module\_regional) | ./modules/regional | n/a |
| <a name="module_vpc_scoped"></a> [vpc\_scoped](#module\_vpc\_scoped) | ./modules/vpc-scoped | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_addons_crossplane_providers"></a> [addons\_crossplane\_providers](#input\_addons\_crossplane\_providers) | Configuration for Crossplane Providers to be enabled as part of the addons installation. | <pre>object({<br/>    enabled = bool<br/><br/>    upboundProviderAwsEC2 = optional(object({<br/>      enabled = bool<br/>    }), null)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_addons_enable"></a> [addons\_enable](#input\_addons\_enable) | Enable or disable Argo Managed addons in the cluster. | `bool` | `true` | no |
| <a name="input_addons_enable_github_runners"></a> [addons\_enable\_github\_runners](#input\_addons\_enable\_github\_runners) | Enable or disable Github Runners in the addons installation. | `bool` | `false` | no |
| <a name="input_addons_enable_kubernetes_event_exporter"></a> [addons\_enable\_kubernetes\_event\_exporter](#input\_addons\_enable\_kubernetes\_event\_exporter) | Enable or disable Kubernetes Event Exporter in the addons installation. | `bool` | `false` | no |
| <a name="input_addons_enable_monitoring"></a> [addons\_enable\_monitoring](#input\_addons\_enable\_monitoring) | Enable or disable Monitoring in the addons installation. | `bool` | `false` | no |
| <a name="input_addons_enable_pci_addons"></a> [addons\_enable\_pci\_addons](#input\_addons\_enable\_pci\_addons) | Enable or disable PCI Addons in the addons installation. | `bool` | `false` | no |
| <a name="input_addons_enable_pci_addons_efs_csi_driver"></a> [addons\_enable\_pci\_addons\_efs\_csi\_driver](#input\_addons\_enable\_pci\_addons\_efs\_csi\_driver) | Enable or disable pci-addons efs-csi-driver. | `bool` | `false` | no |
| <a name="input_addons_enable_pci_addons_patches"></a> [addons\_enable\_pci\_addons\_patches](#input\_addons\_enable\_pci\_addons\_patches) | Enable or disable pci-addons patches. | `bool` | `false` | no |
| <a name="input_addons_enable_stakater_reloader"></a> [addons\_enable\_stakater\_reloader](#input\_addons\_enable\_stakater\_reloader) | Enable or disable Stakater Reloader in the addons installation. | `bool` | `false` | no |
| <a name="input_addons_revision"></a> [addons\_revision](#input\_addons\_revision) | The revision of the Argo Managed addons to apply in the cluster. | `string` | `"dev"` | no |
| <a name="input_alb_access_logs"></a> [alb\_access\_logs](#input\_alb\_access\_logs) | Default access logs configuration for all ALBs. Can be overridden per ALB via var.albs. | <pre>object({<br/>    bucket  = string<br/>    enabled = optional(bool, true)<br/>    prefix  = optional(string, null)<br/>  })</pre> | <pre>{<br/>  "bucket": "central-alb-logs-123456789012-us-east-1",<br/>  "enabled": true,<br/>  "prefix": null<br/>}</pre> | no |
| <a name="input_alb_enable_deletion_protection"></a> [alb\_enable\_deletion\_protection](#input\_alb\_enable\_deletion\_protection) | Default deletion protection setting for all ALBs. Can be overridden per ALB via var.albs. | `bool` | `false` | no |
| <a name="input_alb_enable_http2"></a> [alb\_enable\_http2](#input\_alb\_enable\_http2) | Default HTTP/2 setting for all ALBs. Can be overridden per ALB via var.albs. | `bool` | `false` | no |
| <a name="input_alb_idle_timeout"></a> [alb\_idle\_timeout](#input\_alb\_idle\_timeout) | Default idle timeout (in seconds) for all ALBs. Can be overridden per ALB via var.albs. | `number` | `3600` | no |
| <a name="input_alb_internal_certificate_arn"></a> [alb\_internal\_certificate\_arn](#input\_alb\_internal\_certificate\_arn) | ACM certificate ARN used by the HTTPS listener on the internal ALB. | `string` | `null` | no |
| <a name="input_alb_public_certificate_arn"></a> [alb\_public\_certificate\_arn](#input\_alb\_public\_certificate\_arn) | ACM certificate ARN used by the HTTPS listener on the public ALB. | `string` | `null` | no |
| <a name="input_albs"></a> [albs](#input\_albs) | ALB definitions to merge with the module defaults (local.alb\_default). Values in var.albs override defaults on key conflicts. Each ALB entry supports: create, internal, subnet\_ids, idle\_timeout, enable\_http2, enable\_deletion\_protection, create\_security\_group, security\_group\_ids, security\_group\_ingress\_rules, security\_group\_egress\_rules, access\_logs, and listeners. | `map(any)` | `{}` | no |
| <a name="input_apps_chart_version"></a> [apps\_chart\_version](#input\_apps\_chart\_version) | The version of the Argo CD Apps Helm chart. | `string` | `"2.0.2"` | no |
| <a name="input_argocd_addons_repo_creds_app_id"></a> [argocd\_addons\_repo\_creds\_app\_id](#input\_argocd\_addons\_repo\_creds\_app\_id) | Defines the Github App ID. | `string` | `null` | no |
| <a name="input_argocd_addons_repo_creds_app_installation_id"></a> [argocd\_addons\_repo\_creds\_app\_installation\_id](#input\_argocd\_addons\_repo\_creds\_app\_installation\_id) | Defines the Github installation ID. | `string` | `null` | no |
| <a name="input_argocd_addons_repo_creds_private_key"></a> [argocd\_addons\_repo\_creds\_private\_key](#input\_argocd\_addons\_repo\_creds\_private\_key) | Defines the Github private key. | `string` | `null` | no |
| <a name="input_argocd_addons_repo_list_names"></a> [argocd\_addons\_repo\_list\_names](#input\_argocd\_addons\_repo\_list\_names) | Defines a list of Github repositories names to create the kubernetes secret to authenticate this repositories on ArgoCD. | `list(string)` | <pre>[<br/>  "argocd-infra",<br/>  "platform-ops-charts",<br/>  "platform-charts"<br/>]</pre> | no |
| <a name="input_argocd_repocreds"></a> [argocd\_repocreds](#input\_argocd\_repocreds) | ArgoCD repo-creds Secret overrides/additions keyed by logical id (typically the repo name). Merged on top of local defaults in argocd-repocreds.tf. Set create=false to disable a secret. | `any` | `{}` | no |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID for resource provisioning. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region where resources will be provisioned. | `string` | n/a | yes |
| <a name="input_aws_service_base_security_group_id"></a> [aws\_service\_base\_security\_group\_id](#input\_aws\_service\_base\_security\_group\_id) | Security Group ID used by AWS service base workloads (used by VPC-attached Lambdas). | `string` | `null` | no |
| <a name="input_base_security_group_tags"></a> [base\_security\_group\_tags](#input\_base\_security\_group\_tags) | Tags for the base security group. | `map(string)` | `{}` | no |
| <a name="input_context"></a> [context](#input\_context) | Select which core-infra context to deploy from this root module: global, regional, or vpc-scoped. Each one has a unique state and set of resources it manages. global is for global-level resources (e.g., IAM roles not specific to a region or cluster), regional is for region-specific resources (e.g., RDS option groups, S3 buckets), and vpc-scoped is for VPC-attached resources (e.g., ArgoCD, VPC-attached Lambdas). | `string` | n/a | yes |
| <a name="input_create_alb_internal"></a> [create\_alb\_internal](#input\_create\_alb\_internal) | Determines whether the internal Application Load Balancer will be created. | `bool` | `false` | no |
| <a name="input_create_alb_public"></a> [create\_alb\_public](#input\_create\_alb\_public) | Determines whether the public (internet-facing) Application Load Balancer will be created. | `bool` | `false` | no |
| <a name="input_create_argocd_apps"></a> [create\_argocd\_apps](#input\_create\_argocd\_apps) | Feature flag to enable/disable Argo CD projects and applications (argocd-apps Helm release). When false, no Argo CD apps/projects are created by this stack. | `bool` | `false` | no |
| <a name="input_create_argocd_repocreds"></a> [create\_argocd\_repocreds](#input\_create\_argocd\_repocreds) | Whether to create ArgoCD repo-creds Secrets from the default repo list (argocd\_addons\_repo\_list\_names). | `bool` | `false` | no |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Controls if database subnet group should be created (n.b. database\_subnets must also be set) | `bool` | `false` | no |
| <a name="input_create_ecs_cluster"></a> [create\_ecs\_cluster](#input\_create\_ecs\_cluster) | Determines whether the ECS cluster will be created | `bool` | `false` | no |
| <a name="input_create_iam_role_cloudwatch_exporter"></a> [create\_iam\_role\_cloudwatch\_exporter](#input\_create\_iam\_role\_cloudwatch\_exporter) | Create the IAM role used by the cloudwatch-exporter service account. | `bool` | `true` | no |
| <a name="input_create_iam_role_cross_account_finops"></a> [create\_iam\_role\_cross\_account\_finops](#input\_create\_iam\_role\_cross\_account\_finops) | Create the IAM role to grant read only access to the FinOps AWS account. | `bool` | `false` | no |
| <a name="input_create_iam_role_eventbridge_scheduler"></a> [create\_iam\_role\_eventbridge\_scheduler](#input\_create\_iam\_role\_eventbridge\_scheduler) | Create the IAM Role for the Eventbridge Scheduler. | `bool` | `true` | no |
| <a name="input_create_iam_role_finops_cronjob"></a> [create\_iam\_role\_finops\_cronjob](#input\_create\_iam\_role\_finops\_cronjob) | Create the IAM role used by the finops cronjob service account. | `bool` | `true` | no |
| <a name="input_create_iam_role_prometheus_rds_exporter"></a> [create\_iam\_role\_prometheus\_rds\_exporter](#input\_create\_iam\_role\_prometheus\_rds\_exporter) | Create the IAM role used by the prometheus-rds-exporter service account. | `bool` | `true` | no |
| <a name="input_create_iam_role_rds_enhanced_monitoring"></a> [create\_iam\_role\_rds\_enhanced\_monitoring](#input\_create\_iam\_role\_rds\_enhanced\_monitoring) | Create the IAM Role for Enhanced Monitoring. | `bool` | `true` | no |
| <a name="input_create_iam_role_rds_s3_integration"></a> [create\_iam\_role\_rds\_s3\_integration](#input\_create\_iam\_role\_rds\_s3\_integration) | Create the IAM Role to integrate the RDS with central S3 bucket. | `bool` | `true` | no |
| <a name="input_create_iam_role_step_functions_dump_rds"></a> [create\_iam\_role\_step\_functions\_dump\_rds](#input\_create\_iam\_role\_step\_functions\_dump\_rds) | Create the IAM role used by the dump-rds Step Functions state machine. | `bool` | `true` | no |
| <a name="input_create_iam_role_step_functions_version_update"></a> [create\_iam\_role\_step\_functions\_version\_update](#input\_create\_iam\_role\_step\_functions\_version\_update) | Create the IAM role used by the version-update Step Functions state machine. | `bool` | `true` | no |
| <a name="input_create_igw"></a> [create\_igw](#input\_create\_igw) | Controls if an Internet Gateway is created for public subnets and the related routes that connect them | `bool` | `false` | no |
| <a name="input_create_lambda_rds_create_snapshot"></a> [create\_lambda\_rds\_create\_snapshot](#input\_create\_lambda\_rds\_create\_snapshot) | Create the Lambda function lambda-rds-create-snapshot and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_delete_instance"></a> [create\_lambda\_rds\_delete\_instance](#input\_create\_lambda\_rds\_delete\_instance) | Create the Lambda function lambda-rds-delete-instance and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_delete_snapshot"></a> [create\_lambda\_rds\_delete\_snapshot](#input\_create\_lambda\_rds\_delete\_snapshot) | Create the Lambda function lambda-rds-delete-snapshot and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_modify_instance"></a> [create\_lambda\_rds\_modify\_instance](#input\_create\_lambda\_rds\_modify\_instance) | Create the Lambda function lambda-rds-modify-instance and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_modify_instance_version_update"></a> [create\_lambda\_rds\_modify\_instance\_version\_update](#input\_create\_lambda\_rds\_modify\_instance\_version\_update) | Create the Lambda function lambda-rds-modify-instance-version-update and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_oracle_execute_sql_statements"></a> [create\_lambda\_rds\_oracle\_execute\_sql\_statements](#input\_create\_lambda\_rds\_oracle\_execute\_sql\_statements) | Create the Lambda function lambda-rds-oracle-execute-sql-statements and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_oracle_update_users_credentials"></a> [create\_lambda\_rds\_oracle\_update\_users\_credentials](#input\_create\_lambda\_rds\_oracle\_update\_users\_credentials) | Create the Lambda function lambda-rds-oracle-update-users-credentials and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_restore_snapshot"></a> [create\_lambda\_rds\_restore\_snapshot](#input\_create\_lambda\_rds\_restore\_snapshot) | Create the Lambda function lambda-rds-restore-snapshot and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_start_stop_instance"></a> [create\_lambda\_rds\_start\_stop\_instance](#input\_create\_lambda\_rds\_start\_stop\_instance) | Create the Lambda function lambda-rds-start-stop-instance and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_status_check"></a> [create\_lambda\_rds\_status\_check](#input\_create\_lambda\_rds\_status\_check) | Create the Lambda function lambda-rds-status-check and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_secretsmanager_rds_mysql_password_rotation"></a> [create\_lambda\_secretsmanager\_rds\_mysql\_password\_rotation](#input\_create\_lambda\_secretsmanager\_rds\_mysql\_password\_rotation) | Create the Lambda function lambda-secretsmanager-rds-mysql-password-rotation and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_secretsmanager_rds_oracle_password_rotation"></a> [create\_lambda\_secretsmanager\_rds\_oracle\_password\_rotation](#input\_create\_lambda\_secretsmanager\_rds\_oracle\_password\_rotation) | Create the Lambda function lambda-secretsmanager-rds-oracle-password-rotation and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_valkey_clear_cache"></a> [create\_lambda\_valkey\_clear\_cache](#input\_create\_lambda\_valkey\_clear\_cache) | Create the Lambda function lambda-valkey-clear-cache and its IAM role. | `bool` | `true` | no |
| <a name="input_create_layer_cryptography"></a> [create\_layer\_cryptography](#input\_create\_layer\_cryptography) | Create the Lambda layer layer-cryptography. | `bool` | `true` | no |
| <a name="input_create_layer_mysqldb"></a> [create\_layer\_mysqldb](#input\_create\_layer\_mysqldb) | Create the Lambda layer layer-mysqldb. | `bool` | `true` | no |
| <a name="input_create_layer_oracledb"></a> [create\_layer\_oracledb](#input\_create\_layer\_oracledb) | Create the Lambda layer layer-oracledb. | `bool` | `true` | no |
| <a name="input_create_layer_request"></a> [create\_layer\_request](#input\_create\_layer\_request) | Create the Lambda layer layer-request. | `bool` | `true` | no |
| <a name="input_create_layer_tabulate"></a> [create\_layer\_tabulate](#input\_create\_layer\_tabulate) | Create the Lambda layer layer-tabulate. | `bool` | `true` | no |
| <a name="input_create_layer_valkey_client"></a> [create\_layer\_valkey\_client](#input\_create\_layer\_valkey\_client) | Create the Lambda layer layer-valkey-client. | `bool` | `true` | no |
| <a name="input_create_namespace_platform_ops"></a> [create\_namespace\_platform\_ops](#input\_create\_namespace\_platform\_ops) | Whether to create the Kubernetes namespace 'platform-ops'. | `bool` | `false` | no |
| <a name="input_create_namespace_platform_ops_addons"></a> [create\_namespace\_platform\_ops\_addons](#input\_create\_namespace\_platform\_ops\_addons) | Whether to create the Kubernetes namespace 'platform-ops-addons'. | `bool` | `false` | no |
| <a name="input_create_namespace_platform_ops_customers"></a> [create\_namespace\_platform\_ops\_customers](#input\_create\_namespace\_platform\_ops\_customers) | Whether to create the Kubernetes namespace 'platform-ops-customers'. | `bool` | `false` | no |
| <a name="input_create_namespace_platform_ops_internal"></a> [create\_namespace\_platform\_ops\_internal](#input\_create\_namespace\_platform\_ops\_internal) | Whether to create the Kubernetes namespace 'platform-ops-internal'. | `bool` | `false` | no |
| <a name="input_create_nodepool"></a> [create\_nodepool](#input\_create\_nodepool) | Whether to create Karpenter NodePool manifests from nodepools.tf. When false, no NodePool resources are created. | `bool` | `false` | no |
| <a name="input_create_priority_class"></a> [create\_priority\_class](#input\_create\_priority\_class) | Whether to create Kubernetes PriorityClass resources from the vpc-scoped module. When false, no PriorityClass resources are created. | `bool` | `false` | no |
| <a name="input_create_rds_option_groups"></a> [create\_rds\_option\_groups](#input\_create\_rds\_option\_groups) | Create RDS option groups. | `bool` | `true` | no |
| <a name="input_create_rds_parameter_groups"></a> [create\_rds\_parameter\_groups](#input\_create\_rds\_parameter\_groups) | Create RDS parameter groups. | `bool` | `true` | no |
| <a name="input_create_s3"></a> [create\_s3](#input\_create\_s3) | Create S3 buckets and supporting objects used by this module (e.g., bucket for lambda layers). | `bool` | `true` | no |
| <a name="input_create_secrets_manager"></a> [create\_secrets\_manager](#input\_create\_secrets\_manager) | Create AWS Secrets Manager secrets managed by this module. | `bool` | `true` | no |
| <a name="input_create_sg_custom"></a> [create\_sg\_custom](#input\_create\_sg\_custom) | Create the custom security group (sg-custom). | `bool` | `false` | no |
| <a name="input_create_sg_external_ips"></a> [create\_sg\_external\_ips](#input\_create\_sg\_external\_ips) | Create the external security group (external\_ips). | `bool` | `false` | no |
| <a name="input_create_sg_internal_ips"></a> [create\_sg\_internal\_ips](#input\_create\_sg\_internal\_ips) | Create the security group that allows ingress from the managed prefix list (internal\_ips). | `bool` | `false` | no |
| <a name="input_create_sns_topic"></a> [create\_sns\_topic](#input\_create\_sns\_topic) | Create SNS topic for notifications. | `bool` | `false` | no |
| <a name="input_create_ssm_jumpbox"></a> [create\_ssm\_jumpbox](#input\_create\_ssm\_jumpbox) | Feature flag to enable or disable the creation of the SSM jumpbox resources. | `bool` | `false` | no |
| <a name="input_create_step_function_dump_rds"></a> [create\_step\_function\_dump\_rds](#input\_create\_step\_function\_dump\_rds) | Feature flag to enable/disable all Step Functions state machines in this module. When false, no Step Functions are created (module for\_each becomes empty). | `bool` | `true` | no |
| <a name="input_create_step_function_version_update"></a> [create\_step\_function\_version\_update](#input\_create\_step\_function\_version\_update) | Feature flag to enable/disable all Step Functions state machines in this module. When false, no Step Functions are created (module for\_each becomes empty). | `bool` | `true` | no |
| <a name="input_create_valkey"></a> [create\_valkey](#input\_create\_valkey) | Create the Valkey (ElastiCache) replication group. | `bool` | `true` | no |
| <a name="input_create_valkey_security_group"></a> [create\_valkey\_security\_group](#input\_create\_valkey\_security\_group) | Determines if a security group for Valkey is created | `bool` | `false` | no |
| <a name="input_create_valkey_subnet_group"></a> [create\_valkey\_subnet\_group](#input\_create\_valkey\_subnet\_group) | Determines whether the Elasticache subnet group for Valkey will be created or not | `bool` | `false` | no |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Controls if VPC should be created (it affects almost all resources) | `bool` | `false` | no |
| <a name="input_create_waf"></a> [create\_waf](#input\_create\_waf) | Create AWS WAF resources (using tofu-aws-modules WAF module). | `bool` | `false` | no |
| <a name="input_customers_revision"></a> [customers\_revision](#input\_customers\_revision) | The revision of the customers app to monitor the platform-ops-argocd-infra repository. | `string` | `"main"` | no |
| <a name="input_ecs_cloud_map_namespace_name"></a> [ecs\_cloud\_map\_namespace\_name](#input\_ecs\_cloud\_map\_namespace\_name) | Private DNS namespace name for ECS Service Connect (e.g. svc.local). If null, uses <resource\_prefix>-cluster-ecs.local | `string` | `null` | no |
| <a name="input_ecs_create_cloud_map_namespace"></a> [ecs\_create\_cloud\_map\_namespace](#input\_ecs\_create\_cloud\_map\_namespace) | Create a private Cloud Map namespace for ECS Service Connect | `bool` | `true` | no |
| <a name="input_ecs_ingress_rules"></a> [ecs\_ingress\_rules](#input\_ecs\_ingress\_rules) | Ingress rules for ECS instances | <pre>list(object({<br/>    port = number<br/>    cidr = string<br/>  }))</pre> | `[]` | no |
| <a name="input_ecs_mi_on_demand_memory_mib"></a> [ecs\_mi\_on\_demand\_memory\_mib](#input\_ecs\_mi\_on\_demand\_memory\_mib) | Memory requirements (min/max in MiB) for ECS Managed Instances on-demand capacity provider. | <pre>object({<br/>    min = number<br/>    max = number<br/>  })</pre> | <pre>{<br/>  "max": 8192,<br/>  "min": 1024<br/>}</pre> | no |
| <a name="input_ecs_mi_on_demand_vcpu_count"></a> [ecs\_mi\_on\_demand\_vcpu\_count](#input\_ecs\_mi\_on\_demand\_vcpu\_count) | vCPU requirements (min/max) for ECS Managed Instances on-demand capacity provider. | <pre>object({<br/>    min = number<br/>    max = number<br/>  })</pre> | <pre>{<br/>  "max": 4,<br/>  "min": 1<br/>}</pre> | no |
| <a name="input_ecs_mi_spot_max_price_percentage"></a> [ecs\_mi\_spot\_max\_price\_percentage](#input\_ecs\_mi\_spot\_max\_price\_percentage) | Maximum price percentage over lowest price for spot instances. | `number` | `20` | no |
| <a name="input_ecs_mi_spot_memory_mib"></a> [ecs\_mi\_spot\_memory\_mib](#input\_ecs\_mi\_spot\_memory\_mib) | Memory requirements (min/max in MiB) for ECS Managed Instances spot capacity provider. | <pre>object({<br/>    min = number<br/>    max = number<br/>  })</pre> | <pre>{<br/>  "max": 8192,<br/>  "min": 1024<br/>}</pre> | no |
| <a name="input_ecs_mi_spot_vcpu_count"></a> [ecs\_mi\_spot\_vcpu\_count](#input\_ecs\_mi\_spot\_vcpu\_count) | vCPU requirements (min/max) for ECS Managed Instances spot capacity provider. | <pre>object({<br/>    min = number<br/>    max = number<br/>  })</pre> | <pre>{<br/>  "max": 4,<br/>  "min": 1<br/>}</pre> | no |
| <a name="input_ecs_mi_storage_size_gib"></a> [ecs\_mi\_storage\_size\_gib](#input\_ecs\_mi\_storage\_size\_gib) | Storage size in GiB for ECS Managed Instances. | `number` | `50` | no |
| <a name="input_eks_oidc_provider"></a> [eks\_oidc\_provider](#input\_eks\_oidc\_provider) | EKS OIDC provider URL/identifier. | `string` | `null` | no |
| <a name="input_eks_oidc_provider_arn"></a> [eks\_oidc\_provider\_arn](#input\_eks\_oidc\_provider\_arn) | EKS OIDC provider ARN (used for IAM roles for service accounts). | `string` | `null` | no |
| <a name="input_elasticache_security_group_id"></a> [elasticache\_security\_group\_id](#input\_elasticache\_security\_group\_id) | Security Group ID for Elasticache/Valkey. | `string` | `null` | no |
| <a name="input_elasticache_subnet_group_name"></a> [elasticache\_subnet\_group\_name](#input\_elasticache\_subnet\_group\_name) | Subnet group name for Elasticache/Valkey. | `string` | `null` | no |
| <a name="input_enable_kms_deletion_alert"></a> [enable\_kms\_deletion\_alert](#input\_enable\_kms\_deletion\_alert) | Enable alert for KMS key scheduled for deletion. | `bool` | `false` | no |
| <a name="input_enable_kms_disabled_alert"></a> [enable\_kms\_disabled\_alert](#input\_enable\_kms\_disabled\_alert) | Enable alert for KMS key being disabled. | `bool` | `false` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Should be true if you want to provision NAT Gateways for each of your private networks | `bool` | `false` | no |
| <a name="input_eventbridge_role_name"></a> [eventbridge\_role\_name](#input\_eventbridge\_role\_name) | Optional fixed EventBridge IAM role name used by notification rules. If empty, a default name is generated. | `string` | `""` | no |
| <a name="input_gateway_endpoints"></a> [gateway\_endpoints](#input\_gateway\_endpoints) | List of services to create VPC Gateway endpoints for. | `list(string)` | <pre>[<br/>  "s3"<br/>]</pre> | no |
| <a name="input_iam_role_rds_enhanced_monitoring_arn"></a> [iam\_role\_rds\_enhanced\_monitoring\_arn](#input\_iam\_role\_rds\_enhanced\_monitoring\_arn) | IAM Role ARN for RDS Enhanced Monitoring. Required when create\_lambda\_rds\_modify\_instance=true. | `string` | `null` | no |
| <a name="input_iam_role_rds_s3_integration_arn"></a> [iam\_role\_rds\_s3\_integration\_arn](#input\_iam\_role\_rds\_s3\_integration\_arn) | IAM Role ARN for RDS S3 integration. Required when create\_lambda\_rds\_modify\_instance=true. | `string` | `null` | no |
| <a name="input_iam_roles"></a> [iam\_roles](#input\_iam\_roles) | IAM role definitions to merge with defaults in global/cluster IAM modules. Values in var.iam\_roles override defaults on key conflicts. | `any` | `{}` | no |
| <a name="input_internal_revision"></a> [internal\_revision](#input\_internal\_revision) | The revision of the internal app to monitor the platform-ops-argocd-infra repository. | `string` | `"main"` | no |
| <a name="input_lambda_layer_cryptography_arn"></a> [lambda\_layer\_cryptography\_arn](#input\_lambda\_layer\_cryptography\_arn) | ARN of the regional Lambda layer: cryptography. | `string` | `null` | no |
| <a name="input_lambda_layer_mysqldb_arn"></a> [lambda\_layer\_mysqldb\_arn](#input\_lambda\_layer\_mysqldb\_arn) | ARN of the regional Lambda layer: mysqldb. | `string` | `null` | no |
| <a name="input_lambda_layer_oracledb_arn"></a> [lambda\_layer\_oracledb\_arn](#input\_lambda\_layer\_oracledb\_arn) | ARN of the regional Lambda layer: oracledb. | `string` | `null` | no |
| <a name="input_lambda_layer_request_arn"></a> [lambda\_layer\_request\_arn](#input\_lambda\_layer\_request\_arn) | ARN of the regional Lambda layer: request. | `string` | `null` | no |
| <a name="input_lambda_layer_tabulate_arn"></a> [lambda\_layer\_tabulate\_arn](#input\_lambda\_layer\_tabulate\_arn) | ARN of the regional Lambda layer: tabulate. | `string` | `null` | no |
| <a name="input_lambda_layer_valkey_client_arn"></a> [lambda\_layer\_valkey\_client\_arn](#input\_lambda\_layer\_valkey\_client\_arn) | ARN of the regional Lambda layer: valkey-client. | `string` | `null` | no |
| <a name="input_lambda_rds_create_snapshot_arn"></a> [lambda\_rds\_create\_snapshot\_arn](#input\_lambda\_rds\_create\_snapshot\_arn) | Lambda Function ARN for regional lambda\_rds\_create\_snapshot. | `string` | `null` | no |
| <a name="input_lambda_rds_delete_instance_arn"></a> [lambda\_rds\_delete\_instance\_arn](#input\_lambda\_rds\_delete\_instance\_arn) | Lambda Function ARN for regional lambda\_rds\_delete\_instance. | `string` | `null` | no |
| <a name="input_lambda_rds_delete_snapshot_arn"></a> [lambda\_rds\_delete\_snapshot\_arn](#input\_lambda\_rds\_delete\_snapshot\_arn) | Lambda Function ARN for regional lambda\_rds\_delete\_snapshot. | `string` | `null` | no |
| <a name="input_lambda_rds_modify_instance_arn"></a> [lambda\_rds\_modify\_instance\_arn](#input\_lambda\_rds\_modify\_instance\_arn) | Lambda Function ARN for regional lambda\_rds\_modify\_instance. | `string` | `null` | no |
| <a name="input_lambda_rds_modify_instance_version_update_arn"></a> [lambda\_rds\_modify\_instance\_version\_update\_arn](#input\_lambda\_rds\_modify\_instance\_version\_update\_arn) | Lambda Function ARN for regional lambda\_rds\_modify\_instance\_version\_update. | `string` | `null` | no |
| <a name="input_lambda_rds_restore_snapshot_arn"></a> [lambda\_rds\_restore\_snapshot\_arn](#input\_lambda\_rds\_restore\_snapshot\_arn) | Lambda Function ARN for regional lambda\_rds\_restore\_snapshot. | `string` | `null` | no |
| <a name="input_lambda_rds_status_check_arn"></a> [lambda\_rds\_status\_check\_arn](#input\_lambda\_rds\_status\_check\_arn) | Lambda Function ARN for regional lambda\_rds\_status\_check. | `string` | `null` | no |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | Controls if instances launched in the public subnets should receive a public IP address. | `bool` | `false` | no |
| <a name="input_namespaces"></a> [namespaces](#input\_namespaces) | Kubernetes namespace overrides/additions keyed by logical id. Merged on top of local defaults in namespace.tf. Set create=false to disable a namespace. | `any` | `{}` | no |
| <a name="input_nodepools"></a> [nodepools](#input\_nodepools) | NodePool manifest overrides/additions keyed by nodepool name. Merged on top of local defaults in nodepools.tf. | `any` | `{}` | no |
| <a name="input_notifications_eventbridge_rules"></a> [notifications\_eventbridge\_rules](#input\_notifications\_eventbridge\_rules) | Additional/override EventBridge rules map (merged on top of the defaults when enabled). | `any` | `{}` | no |
| <a name="input_notifications_eventbridge_targets"></a> [notifications\_eventbridge\_targets](#input\_notifications\_eventbridge\_targets) | Additional/override EventBridge targets map (merged on top of the defaults when enabled). | `any` | `{}` | no |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs` | `bool` | `false` | no |
| <a name="input_priority_classes"></a> [priority\_classes](#input\_priority\_classes) | Kubernetes PriorityClass overrides/additions keyed by logical id. Merged on top of local defaults in priority-class.tf. Each value should include at least 'value' (number) and optionally 'metadata.name', 'global\_default', 'preemption\_policy', 'description'. | `any` | `{}` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnet IDs used for VPC-attached Lambdas. | `list(string)` | `null` | no |
| <a name="input_public_subnet_id"></a> [public\_subnet\_id](#input\_public\_subnet\_id) | List of public subnet IDs to use for cluster resources. | `list(string)` | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | Public subnet IDs that can be used by internet-facing resources such as an ALB. | `list(string)` | `[]` | no |
| <a name="input_rds_option_groups"></a> [rds\_option\_groups](#input\_rds\_option\_groups) | Map of option groups to create. Keys are logical identifiers; values define name/engine/options. | `any` | `{}` | no |
| <a name="input_rds_parameter_groups"></a> [rds\_parameter\_groups](#input\_rds\_parameter\_groups) | Map of parameter groups to create. Keys are logical identifiers; values define name/family/parameters. | `any` | `{}` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Resource prefix for AWS Core resources. Needs to be unique per AWS (sub) account. | `string` | n/a | yes |
| <a name="input_s3_buckets"></a> [s3\_buckets](#input\_s3\_buckets) | Map of S3 buckets to create. Keys are logical identifiers; values are passed into terraform-aws-modules/s3-bucket. | `any` | `{}` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | Security Group module input overrides merged on top of local defaults in security-groups.tf. Use this to override name/description/ingress/egress/tags or to disable a SG by setting create=false. | `any` | `{}` | no |
| <a name="input_sg_custom_ips"></a> [sg\_custom\_ips](#input\_sg\_custom\_ips) | Comma-separated CIDR blocks allowed to reach Oracle (1521) and MySQL (3306) through sg-custom. Example: '1.2.3.4/32,5.6.7.8/32'. | `string` | `""` | no |
| <a name="input_sg_external_ips_list"></a> [sg\_external\_ips\_list](#input\_sg\_external\_ips\_list) | CIDR blocks allowed as ingress on external\_ips (all protocols/ports). Starts empty and can be expanded when external IPs are provided. | `list(string)` | `[]` | no |
| <a name="input_sg_internal_ips_list"></a> [sg\_internal\_ips\_list](#input\_sg\_internal\_ips\_list) | Additional CIDR blocks allowed as ingress (all protocols/ports). Example: ['1.2.3.4/32','5.6.7.8/32']. | `list(string)` | `[]` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | `bool` | `false` | no |
| <a name="input_sns_topic_arn_override"></a> [sns\_topic\_arn\_override](#input\_sns\_topic\_arn\_override) | Use an existing SNS Topic ARN if not creating one with Terraform. | `string` | `""` | no |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | Name of the SNS topic. | `string` | `"platform-ops-notifications"` | no |
| <a name="input_sns_topic_subscription_email"></a> [sns\_topic\_subscription\_email](#input\_sns\_topic\_subscription\_email) | Email address to subscribe to the notifications SNS topic. | `string` | `""` | no |
| <a name="input_sns_topic_subscriptions"></a> [sns\_topic\_subscriptions](#input\_sns\_topic\_subscriptions) | Optional SNS subscriptions map passed to terraform-aws-modules/sns. When set (non-empty), it overrides sns\_topic\_subscription\_email. | <pre>map(object({<br/>    protocol = string<br/>    endpoint = string<br/>  }))</pre> | `{}` | no |
| <a name="input_ssm_jumpbox_desired_capacity"></a> [ssm\_jumpbox\_desired\_capacity](#input\_ssm\_jumpbox\_desired\_capacity) | Desired number of SSM jumpbox instances. Set to 1 to launch, 0 to terminate. | `number` | `1` | no |
| <a name="input_ssm_jumpbox_instance_type"></a> [ssm\_jumpbox\_instance\_type](#input\_ssm\_jumpbox\_instance\_type) | The EC2 instance type for the SSM jumpbox. | `string` | `"t4g.micro"` | no |
| <a name="input_step_functions"></a> [step\_functions](#input\_step\_functions) | Step Functions module input overrides merged on top of local defaults in step-functions.tf. Use this to override name/definition/logging/timeouts or to disable a state machine by setting create=false. | `any` | `{}` | no |
| <a name="input_sync_windows_ops"></a> [sync\_windows\_ops](#input\_sync\_windows\_ops) | ArgoCD sync windows for the platform-ops projects. | <pre>list(object({<br/>    kind         = optional(string, "allow")<br/>    schedule     = optional(string, "0 12 * * 1")<br/>    duration     = optional(string, "1h")<br/>    timeZone     = optional(string, "")<br/>    manualSync   = optional(bool, true)<br/>    namespaces   = optional(list(string), ["*"])<br/>    clusters     = optional(list(string), ["*"])<br/>    applications = optional(list(string), ["*"])<br/>  }))</pre> | `[]` | no |
| <a name="input_sync_windows_ops_customers"></a> [sync\_windows\_ops\_customers](#input\_sync\_windows\_ops\_customers) | ArgoCD sync windows for the platform-ops-customers project. | <pre>list(object({<br/>    kind         = optional(string, "allow")<br/>    schedule     = optional(string, "0 12 * * 1")<br/>    duration     = optional(string, "1h")<br/>    timeZone     = optional(string, "")<br/>    manualSync   = optional(bool, true)<br/>    namespaces   = optional(list(string), ["*"])<br/>    clusters     = optional(list(string), ["*"])<br/>    applications = optional(list(string), ["*"])<br/>  }))</pre> | <pre>[<br/>  {<br/>    "applications": [<br/>      "*"<br/>    ],<br/>    "clusters": [<br/>      "*"<br/>    ],<br/>    "duration": "1h",<br/>    "kind": "allow",<br/>    "manualSync": true,<br/>    "namespaces": [<br/>      "*"<br/>    ],<br/>    "schedule": "0 12 * * 1",<br/>    "timeZone": ""<br/>  }<br/>]</pre> | no |
| <a name="input_sync_windows_ops_internal"></a> [sync\_windows\_ops\_internal](#input\_sync\_windows\_ops\_internal) | ArgoCD sync windows for the platform-ops-internal project. | <pre>list(object({<br/>    kind         = optional(string, "allow")<br/>    schedule     = optional(string, "0 12 * * 1")<br/>    duration     = optional(string, "1h")<br/>    timeZone     = optional(string, "")<br/>    manualSync   = optional(bool, true)<br/>    namespaces   = optional(list(string), ["*"])<br/>    clusters     = optional(list(string), ["*"])<br/>    applications = optional(list(string), ["*"])<br/>  }))</pre> | <pre>[<br/>  {<br/>    "applications": [<br/>      "*"<br/>    ],<br/>    "clusters": [<br/>      "*"<br/>    ],<br/>    "duration": "1h",<br/>    "kind": "allow",<br/>    "manualSync": true,<br/>    "namespaces": [<br/>      "*"<br/>    ],<br/>    "schedule": "0 12 * * 1",<br/>    "timeZone": ""<br/>  }<br/>]</pre> | no |
| <a name="input_app_env_secrets"></a> [appserver\_env\_secrets](#input\_appserver\_env\_secrets) | Per-environment Secrets Manager secret configuration overrides for the AppServer credentials. Merged on top of defaults in secrets-manager.tf. | `any` | `{}` | no |
| <a name="input_valkey_engine_version"></a> [valkey\_engine\_version](#input\_valkey\_engine\_version) | Valkey engine version used by ElastiCache. | `string` | `"8.0"` | no |
| <a name="input_valkey_maintenance_window"></a> [valkey\_maintenance\_window](#input\_valkey\_maintenance\_window) | Maintenance window for Valkey (UTC). Example: 'Mon:00:00-Mon:03:00'. | `string` | `"sun:00:00-sun:04:00"` | no |
| <a name="input_valkey_multi_az"></a> [valkey\_multi\_az](#input\_valkey\_multi\_az) | Enable Multi-AZ for Valkey. When true, two cache clusters are created with automatic failover enabled. | `bool` | `false` | no |
| <a name="input_valkey_node_type"></a> [valkey\_node\_type](#input\_valkey\_node\_type) | ElastiCache node type for Valkey (e.g., cache.t4g.small). | `string` | `"cache.t3.small"` | no |
| <a name="input_valkeys"></a> [valkeys](#input\_valkeys) | Valkey/ElastiCache module input overrides merged on top of local defaults in valkey.tf. Use this to override module inputs or to disable a cluster by setting create=false. | `any` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC subnet in CIDR notation. | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where vpc-scoped resources are deployed. | `string` | `null` | no |
| <a name="input_waf"></a> [waf](#input\_waf) | WAF module input overrides. Merged on top of the defaults defined in waf.tf locals. | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb"></a> [alb](#output\_alb) | Primary Application Load Balancer attributes. Returns the private ALB when both schemas are created. |
| <a name="output_alb_arn"></a> [alb\_arn](#output\_alb\_arn) | n/a |
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | n/a |
| <a name="output_alb_listener_arn"></a> [alb\_listener\_arn](#output\_alb\_listener\_arn) | Map of listener ARNs keyed by schema and listener name. Example: alb\_listener\_arn["public"]["https"] |
| <a name="output_alb_primary_listener_arn"></a> [alb\_primary\_listener\_arn](#output\_alb\_primary\_listener\_arn) | Listener ARNs of the primary ALB (internal if exists, otherwise public). Example: alb\_primary\_listener\_arn["https"] |
| <a name="output_alb_primary_security_group_id"></a> [alb\_primary\_security\_group\_id](#output\_alb\_primary\_security\_group\_id) | Security group ID of the primary ALB (private if exists, otherwise public). |
| <a name="output_alb_security_group_id"></a> [alb\_security\_group\_id](#output\_alb\_security\_group\_id) | n/a |
| <a name="output_alb_zone_id"></a> [alb\_zone\_id](#output\_alb\_zone\_id) | n/a |
| <a name="output_albs"></a> [albs](#output\_albs) | Application Load Balancer attributes keyed by schema (public/private). |
| <a name="output_aws_database_security_group"></a> [aws\_database\_security\_group](#output\_aws\_database\_security\_group) | AWS database security group |
| <a name="output_aws_service_base_security_group"></a> [aws\_service\_base\_security\_group](#output\_aws\_service\_base\_security\_group) | AWS service base security group |
| <a name="output_database_route_table_ids"></a> [database\_route\_table\_ids](#output\_database\_route\_table\_ids) | Database subnet route table IDs |
| <a name="output_database_subnets"></a> [database\_subnets](#output\_database\_subnets) | Database subnet IDs |
| <a name="output_db_private_subnet_group"></a> [db\_private\_subnet\_group](#output\_db\_private\_subnet\_group) | n/a |
| <a name="output_db_public_subnet_group"></a> [db\_public\_subnet\_group](#output\_db\_public\_subnet\_group) | n/a |
| <a name="output_default_security_group_id"></a> [default\_security\_group\_id](#output\_default\_security\_group\_id) | n/a |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | n/a |
| <a name="output_ecs_cluster_cloud_map_namespace_arn"></a> [ecs\_cluster\_cloud\_map\_namespace\_arn](#output\_ecs\_cluster\_cloud\_map\_namespace\_arn) | n/a |
| <a name="output_ecs_cluster_cloud_map_namespace_id"></a> [ecs\_cluster\_cloud\_map\_namespace\_id](#output\_ecs\_cluster\_cloud\_map\_namespace\_id) | n/a |
| <a name="output_ecs_cluster_cloud_map_namespace_name"></a> [ecs\_cluster\_cloud\_map\_namespace\_name](#output\_ecs\_cluster\_cloud\_map\_namespace\_name) | n/a |
| <a name="output_ecs_cluster_id"></a> [ecs\_cluster\_id](#output\_ecs\_cluster\_id) | n/a |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | n/a |
| <a name="output_ecs_cluster_security_group_id"></a> [ecs\_cluster\_security\_group\_id](#output\_ecs\_cluster\_security\_group\_id) | n/a |
| <a name="output_elasticache_valkey"></a> [elasticache\_valkey](#output\_elasticache\_valkey) | n/a |
| <a name="output_elasticache_valkey_all"></a> [elasticache\_valkey\_all](#output\_elasticache\_valkey\_all) | All Valkey module instances (keyed by valkeys map key) |
| <a name="output_iam_roles"></a> [iam\_roles](#output\_iam\_roles) | n/a |
| <a name="output_igw_arn"></a> [igw\_arn](#output\_igw\_arn) | The ARN of the Internet Gateway |
| <a name="output_igw_id"></a> [igw\_id](#output\_igw\_id) | The ID of the Internet Gateway |
| <a name="output_lambda_rds_create_snapshot"></a> [lambda\_rds\_create\_snapshot](#output\_lambda\_rds\_create\_snapshot) | n/a |
| <a name="output_lambda_rds_delete_instance"></a> [lambda\_rds\_delete\_instance](#output\_lambda\_rds\_delete\_instance) | n/a |
| <a name="output_lambda_rds_delete_snapshot"></a> [lambda\_rds\_delete\_snapshot](#output\_lambda\_rds\_delete\_snapshot) | n/a |
| <a name="output_lambda_rds_modify_instance"></a> [lambda\_rds\_modify\_instance](#output\_lambda\_rds\_modify\_instance) | n/a |
| <a name="output_lambda_rds_modify_instance_version_update"></a> [lambda\_rds\_modify\_instance\_version\_update](#output\_lambda\_rds\_modify\_instance\_version\_update) | n/a |
| <a name="output_lambda_rds_oracle_execute_sql_statements"></a> [lambda\_rds\_oracle\_execute\_sql\_statements](#output\_lambda\_rds\_oracle\_execute\_sql\_statements) | n/a |
| <a name="output_lambda_rds_oracle_update_users_credentials"></a> [lambda\_rds\_oracle\_update\_users\_credentials](#output\_lambda\_rds\_oracle\_update\_users\_credentials) | n/a |
| <a name="output_lambda_rds_restore_snapshot"></a> [lambda\_rds\_restore\_snapshot](#output\_lambda\_rds\_restore\_snapshot) | n/a |
| <a name="output_lambda_rds_start_stop_instance"></a> [lambda\_rds\_start\_stop\_instance](#output\_lambda\_rds\_start\_stop\_instance) | n/a |
| <a name="output_lambda_rds_status_check"></a> [lambda\_rds\_status\_check](#output\_lambda\_rds\_status\_check) | n/a |
| <a name="output_lambda_secretsmanager_rds_mysql_password_rotation"></a> [lambda\_secretsmanager\_rds\_mysql\_password\_rotation](#output\_lambda\_secretsmanager\_rds\_mysql\_password\_rotation) | n/a |
| <a name="output_lambda_secretsmanager_rds_oracle_password_rotation"></a> [lambda\_secretsmanager\_rds\_oracle\_password\_rotation](#output\_lambda\_secretsmanager\_rds\_oracle\_password\_rotation) | n/a |
| <a name="output_lambda_valkey_clear_cache"></a> [lambda\_valkey\_clear\_cache](#output\_lambda\_valkey\_clear\_cache) | n/a |
| <a name="output_layer_cryptography"></a> [layer\_cryptography](#output\_layer\_cryptography) | n/a |
| <a name="output_layer_mysqldb"></a> [layer\_mysqldb](#output\_layer\_mysqldb) | n/a |
| <a name="output_layer_oracledb"></a> [layer\_oracledb](#output\_layer\_oracledb) | n/a |
| <a name="output_layer_request"></a> [layer\_request](#output\_layer\_request) | n/a |
| <a name="output_layer_tabulate"></a> [layer\_tabulate](#output\_layer\_tabulate) | n/a |
| <a name="output_layer_valkey_client"></a> [layer\_valkey\_client](#output\_layer\_valkey\_client) | n/a |
| <a name="output_nat_public_ips"></a> [nat\_public\_ips](#output\_nat\_public\_ips) | NAT Gateway Elastic IPs |
| <a name="output_natgw_ids"></a> [natgw\_ids](#output\_natgw\_ids) | List of NAT Gateway IDs |
| <a name="output_option_group_arns"></a> [option\_group\_arns](#output\_option\_group\_arns) | Map of option group ARNs |
| <a name="output_option_group_ids"></a> [option\_group\_ids](#output\_option\_group\_ids) | Map of option group IDs |
| <a name="output_option_groups"></a> [option\_groups](#output\_option\_groups) | Map of all option groups created |
| <a name="output_option_groups_names"></a> [option\_groups\_names](#output\_option\_groups\_names) | Map of option group names keyed by option\_groups keys |
| <a name="output_parameter_group_arns"></a> [parameter\_group\_arns](#output\_parameter\_group\_arns) | Map of parameter group ARNs keyed by parameter\_groups keys |
| <a name="output_parameter_group_ids"></a> [parameter\_group\_ids](#output\_parameter\_group\_ids) | Map of parameter group IDs keyed by parameter\_groups keys |
| <a name="output_parameter_group_names"></a> [parameter\_group\_names](#output\_parameter\_group\_names) | Map of parameter group names keyed by parameter\_groups keys |
| <a name="output_parameter_groups"></a> [parameter\_groups](#output\_parameter\_groups) | Map of all parameter groups created |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | Private subnet route table IDs |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | Private subnet IDs |
| <a name="output_public_route_table_ids"></a> [public\_route\_table\_ids](#output\_public\_route\_table\_ids) | Public subnet route table IDs |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | Public subnet IDs |
| <a name="output_s3_bucket_arns"></a> [s3\_bucket\_arns](#output\_s3\_bucket\_arns) | Map of S3 bucket ARNs |
| <a name="output_s3_bucket_ids"></a> [s3\_bucket\_ids](#output\_s3\_bucket\_ids) | Map of S3 bucket IDs |
| <a name="output_s3_buckets"></a> [s3\_buckets](#output\_s3\_buckets) | Map of S3 buckets created |
| <a name="output_security_groups"></a> [security\_groups](#output\_security\_groups) | n/a |
| <a name="output_ssm_jumpbox_autoscaling_group_name"></a> [ssm\_jumpbox\_autoscaling\_group\_name](#output\_ssm\_jumpbox\_autoscaling\_group\_name) | SSM jumpbox autoscaling group name |
| <a name="output_ssm_jumpbox_launch_template_id"></a> [ssm\_jumpbox\_launch\_template\_id](#output\_ssm\_jumpbox\_launch\_template\_id) | SSM jumpbox launch template ID |
| <a name="output_ssm_jumpbox_security_group"></a> [ssm\_jumpbox\_security\_group](#output\_ssm\_jumpbox\_security\_group) | SSM jumpbox security group |
| <a name="output_step_functions"></a> [step\_functions](#output\_step\_functions) | n/a |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | VPC CIDR block |
| <a name="output_vpc_endpoints"></a> [vpc\_endpoints](#output\_vpc\_endpoints) | VPC endpoints created |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
<!-- END_TF_DOCS -->