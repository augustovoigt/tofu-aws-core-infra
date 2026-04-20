# core-infra — vpc-scoped

Deploys **VPC-level** resources specific to a single EKS cluster or ECS environment.

This module runs **once per VPC / cluster** and creates compute, caching, application delivery, and Kubernetes management resources. In the caller repo (`tofu-aws-infra`), each VPC gets its own OpenTofu state (`core-vpc-scoped`), allowing multiple environments (e.g., prod + staging) or multi-cluster setups to be planned and applied independently — without touching global or regional resources.

## What this module creates

### Compute & Networking

| Resource | Description | Feature flag |
|---|---|---|
| **ECS Cluster** | Cluster with ON_DEMAND and SPOT capacity providers (managed instances) | `create_ecs_cluster` |
| **Cloud Map Namespace** | Private DNS for ECS Service Connect | `ecs_create_cloud_map_namespace` |
| **ALB (Public)** | Internet-facing load balancer with HTTPS listener | `create_alb_public` |
| **ALB (Internal)** | Internal load balancer with HTTPS listener | `create_alb_internal` |
| **Security Groups** | Internal IPs, external IPs, customer IPs, and custom SGs | `create_sg_*` |
| **Valkey (ElastiCache)** | Redis-compatible cache cluster with encryption and optional Multi-AZ | `create_valkey` |

### Lambda & Orchestration

| Resource | Description | Feature flag |
|---|---|---|
| **RDS Oracle SQL Execution** | Runs SQL statements against Oracle RDS instances | `create_lambda_rds_oracle_execute_sql_statements` |
| **RDS User Credential Updates** | Rotates Oracle database user credentials | `create_lambda_rds_oracle_update_users_credentials` |
| **Valkey Cache Clear** | Flushes Valkey cache entries | `create_lambda_valkey_clear_cache` |
| **Secrets Manager Rotation (Oracle)** | Automatic password rotation for Oracle RDS | `create_lambda_secretsmanager_rds_oracle_password_rotation` |
| **Secrets Manager Rotation (MySQL)** | Automatic password rotation for MySQL RDS | `create_lambda_secretsmanager_rds_mysql_password_rotation` |
| **Step Functions — RDS Dump** | State machine for automated RDS snapshot/restore workflows | `create_step_function_dump_rds` |
| **Step Functions — Version Update** | State machine for RDS engine version updates | `create_step_function_version_update` |

### Kubernetes (EKS only)

| Resource | Description | Feature flag |
|---|---|---|
| **Namespaces** | platform-ops, platform-ops-addons, platform-ops-customers, platform-ops-internal | `create_namespace_platform_ops*` |
| **Karpenter NodePools** | Auto-scaling node pools per environment | `create_nodepool` |
| **PriorityClasses** | top-priority, secrets-objects, prod, nonprod | `create_priority_class` |
| **ArgoCD App Projects** | platform-ops, platform-ops-customers, platform-ops-internal | `create_argocd_apps` |
| **ArgoCD Addons** | Monitoring, GitHub Runners, PCI, Reloader, Event Exporter | `addons_enable_*` |
| **ArgoCD Repo Credentials** | GitHub App authentication secrets | `create_argocd_repocreds` |

### IAM Roles (IRSA)

| Resource | Description | Feature flag |
|---|---|---|
| **CloudWatch Exporter** | Service account role for CloudWatch metrics export | `create_iam_role_cloudwatch_exporter` |
| **Prometheus RDS Exporter** | Service account role for RDS metrics scraping | `create_iam_role_prometheus_rds_exporter` |
| **FinOps CronJob** | Service account role for cost reporting | `create_iam_role_finops_cronjob` |
| **Step Functions Dump RDS** | Execution role for dump-rds state machine | `create_iam_role_step_functions_dump_rds` |
| **Step Functions Version Update** | Execution role for version-update state machine | `create_iam_role_step_functions_version_update` |

## Usage

```hcl
module "core_vpc_scoped" {
  source = "git::https://github.com/augustovoigt/tofu-aws-core-infra.git//modules/vpc-scoped?ref=<tag>"

  aws_region      = "us-east-1"
  aws_account_id  = "123456789012"
  resource_prefix = "myproject"

  # VPC
  vpc_id                             = module.core_regional.vpc_id
  aws_service_base_security_group_id = module.core_regional.aws_service_base_security_group.id
  private_subnet_ids                 = module.core_regional.private_subnets

  # EKS (required for K8s resources and IRSA)
  eks_oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn
  eks_oidc_provider     = data.terraform_remote_state.eks.outputs.oidc_provider

  # Elasticache
  elasticache_security_group_id = data.terraform_remote_state.vpc.outputs.security_groups.elasticache.id
  elasticache_subnet_group_name = data.terraform_remote_state.vpc.outputs.subnet_groups.elasticache.name

  # Regional Lambda ARNs
  lambda_rds_create_snapshot_arn                = module.core_regional.lambda_rds_create_snapshot.lambda_function_arn
  lambda_rds_delete_instance_arn                = module.core_regional.lambda_rds_delete_instance.lambda_function_arn
  lambda_rds_restore_snapshot_arn               = module.core_regional.lambda_rds_restore_snapshot.lambda_function_arn
  lambda_rds_modify_instance_arn                = module.core_regional.lambda_rds_modify_instance.lambda_function_arn
  lambda_rds_delete_snapshot_arn                = module.core_regional.lambda_rds_delete_snapshot.lambda_function_arn
  lambda_rds_status_check_arn                   = module.core_regional.lambda_rds_status_check.lambda_function_arn
  lambda_rds_modify_instance_version_update_arn = module.core_regional.lambda_rds_modify_instance_version_update.lambda_function_arn

  # Regional Lambda Layer ARNs
  lambda_layer_oracledb_arn      = module.core_regional.layer_oracledb.lambda_layer_arn
  lambda_layer_tabulate_arn      = module.core_regional.layer_tabulate.lambda_layer_arn
  lambda_layer_valkey_client_arn = module.core_regional.layer_valkey_client.lambda_layer_arn
  lambda_layer_request_arn       = module.core_regional.layer_request.lambda_layer_arn

  # Kubernetes
  create_namespace_platform_ops          = true
  create_namespace_platform_ops_addons   = true
  create_nodepool                        = true
  create_priority_class                  = true

  # ArgoCD
  create_argocd_apps       = true
  create_argocd_repocreds  = true
  argocd_addons_repo_creds_app_id              = var.github_app_id
  argocd_addons_repo_creds_app_installation_id = var.github_app_installation_id
  argocd_addons_repo_creds_private_key         = var.github_app_private_key
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

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | ~> 3.1.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | ~> 2.1.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 3.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | terraform-aws-modules/ecs/aws | n/a |
| <a name="module_elasticache_valkey"></a> [elasticache\_valkey](#module\_elasticache\_valkey) | terraform-aws-modules/elasticache/aws | 1.11.0 |
| <a name="module_iam_roles"></a> [iam\_roles](#module\_iam\_roles) | terraform-aws-modules/iam/aws//modules/iam-role | 6.4.0 |
| <a name="module_lambda_rds_oracle_execute_sql_statements"></a> [lambda\_rds\_oracle\_execute\_sql\_statements](#module\_lambda\_rds\_oracle\_execute\_sql\_statements) | ./lambdas/lambda-rds-oracle-execute-sql-statements | n/a |
| <a name="module_lambda_rds_oracle_update_users_credentials"></a> [lambda\_rds\_oracle\_update\_users\_credentials](#module\_lambda\_rds\_oracle\_update\_users\_credentials) | ./lambdas/lambda-rds-oracle-update-users-credentials | n/a |
| <a name="module_lambda_secretsmanager_rds_mysql_password_rotation"></a> [lambda\_secretsmanager\_rds\_mysql\_password\_rotation](#module\_lambda\_secretsmanager\_rds\_mysql\_password\_rotation) | ./lambdas/lambda-secretsmanager-rds-mysql-password-rotation | n/a |
| <a name="module_lambda_secretsmanager_rds_oracle_password_rotation"></a> [lambda\_secretsmanager\_rds\_oracle\_password\_rotation](#module\_lambda\_secretsmanager\_rds\_oracle\_password\_rotation) | ./lambdas/lambda-secretsmanager-rds-oracle-password-rotation | n/a |
| <a name="module_lambda_valkey_clear_cache"></a> [lambda\_valkey\_clear\_cache](#module\_lambda\_valkey\_clear\_cache) | ./lambdas/lambda-valkey-clear-cache | n/a |
| <a name="module_security_groups"></a> [security\_groups](#module\_security\_groups) | terraform-aws-modules/security-group/aws | 5.3.1 |
| <a name="module_step_functions"></a> [step\_functions](#module\_step\_functions) | terraform-aws-modules/step-functions/aws | 5.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_instance_profile.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.ecs_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_service_discovery_private_dns_namespace.ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_vpc_security_group_egress_rule.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [helm_release.cluster_apps](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.this](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.namespaces](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_priority_class_v1.priority_classes](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/priority_class_v1) | resource |
| [kubernetes_secret_v1.repocreds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [aws_ec2_managed_prefix_list.internal_ips](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_managed_prefix_list) | data source |
| [aws_ssm_parameter.ecs_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

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
| <a name="input_apps_chart_version"></a> [apps\_chart\_version](#input\_apps\_chart\_version) | The version of the Argo CD Apps Helm chart. | `string` | `"2.0.2"` | no |
| <a name="input_argocd_addons_repo_creds_app_id"></a> [argocd\_addons\_repo\_creds\_app\_id](#input\_argocd\_addons\_repo\_creds\_app\_id) | Defines the Github App ID. | `string` | n/a | yes |
| <a name="input_argocd_addons_repo_creds_app_installation_id"></a> [argocd\_addons\_repo\_creds\_app\_installation\_id](#input\_argocd\_addons\_repo\_creds\_app\_installation\_id) | Defines the Github installation ID. | `string` | n/a | yes |
| <a name="input_argocd_addons_repo_creds_private_key"></a> [argocd\_addons\_repo\_creds\_private\_key](#input\_argocd\_addons\_repo\_creds\_private\_key) | Defines the Github private key. | `string` | n/a | yes |
| <a name="input_argocd_addons_repo_list_names"></a> [argocd\_addons\_repo\_list\_names](#input\_argocd\_addons\_repo\_list\_names) | Defines a list of Github repositories names to create the kubernetes secret to authenticate this repositories on ArgoCD. | `list(string)` | <pre>[<br/>  "argocd-infra",<br/>  "platform-ops-charts",<br/>  "platform-charts"<br/>]</pre> | no |
| <a name="input_argocd_repocreds"></a> [argocd\_repocreds](#input\_argocd\_repocreds) | ArgoCD repo-creds Secret overrides/additions keyed by logical id (typically the repo name). Merged on top of local defaults in argocd-repocreds.tf. Set create=false to disable a secret. | `any` | `{}` | no |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID for resource provisioning. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region where resources will be provisioned. | `string` | n/a | yes |
| <a name="input_aws_service_base_security_group_id"></a> [aws\_service\_base\_security\_group\_id](#input\_aws\_service\_base\_security\_group\_id) | Security Group ID used by AWS service base workloads (used by VPC-attached Lambdas). | `string` | n/a | yes |
| <a name="input_alb_security_group_ids"></a> [alb\_security\_group\_ids](#input\_alb\_security\_group\_ids) | Existing security group IDs to attach to the ALB. When provided, the module will not create a dedicated ALB security group. | `list(string)` | `null` | no |
| <a name="input_ecs_cloud_map_namespace_name"></a> [ecs\_cloud\_map\_namespace\_name](#input\_ecs\_cloud\_map\_namespace\_name) | Private DNS namespace name for ECS Service Connect (e.g. svc.local). If null, uses <resource\_prefix>-cluster-ecs.local | `string` | `null` | no |
| <a name="input_create_argocd_apps"></a> [create\_argocd\_apps](#input\_create\_argocd\_apps) | Feature flag to enable/disable Argo CD projects and applications (argocd-apps Helm release). When false, no Argo CD apps/projects are created by this stack. | `bool` | `false` | no |
| <a name="input_create_argocd_repocreds"></a> [create\_argocd\_repocreds](#input\_create\_argocd\_repocreds) | Whether to create ArgoCD repo-creds Secrets from the default repo list (argocd\_addons\_repo\_list\_names). Individual secrets can still be enabled/disabled via argocd\_repocreds.*.create. | `bool` | `false` | no |
| <a name="input_ecs_create_cloud_map_namespace"></a> [ecs\_create\_cloud\_map\_namespace](#input\_ecs\_create\_cloud\_map\_namespace) | Create a private Cloud Map namespace for ECS Service Connect | `bool` | `true` | no |
| <a name="input_create_ecs_cluster"></a> [create\_ecs\_cluster](#input\_create\_ecs\_cluster) | Determines whether the ECS cluster will be created | `bool` | `false` | no |
| <a name="input_create_iam_role_cloudwatch_exporter"></a> [create\_iam\_role\_cloudwatch\_exporter](#input\_create\_iam\_role\_cloudwatch\_exporter) | Create the IAM role used by the cloudwatch-exporter service account. | `bool` | `true` | no |
| <a name="input_create_iam_role_finops_cronjob"></a> [create\_iam\_role\_finops\_cronjob](#input\_create\_iam\_role\_finops\_cronjob) | Create the IAM role used by the finops cronjob service account. | `bool` | `false` | no |
| <a name="input_create_iam_role_prometheus_rds_exporter"></a> [create\_iam\_role\_prometheus\_rds\_exporter](#input\_create\_iam\_role\_prometheus\_rds\_exporter) | Create the IAM role used by the prometheus-rds-exporter service account. | `bool` | `false` | no |
| <a name="input_create_iam_role_step_functions_dump_rds"></a> [create\_iam\_role\_step\_functions\_dump\_rds](#input\_create\_iam\_role\_step\_functions\_dump\_rds) | Create the IAM role used by the dump-rds Step Functions state machine. | `bool` | `true` | no |
| <a name="input_create_iam_role_step_functions_version_update"></a> [create\_iam\_role\_step\_functions\_version\_update](#input\_create\_iam\_role\_step\_functions\_version\_update) | Create the IAM role used by the version-update Step Functions state machine. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_oracle_execute_sql_statements"></a> [create\_lambda\_rds\_oracle\_execute\_sql\_statements](#input\_create\_lambda\_rds\_oracle\_execute\_sql\_statements) | Create the Lambda function lambda-rds-oracle-execute-sql-statements and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_oracle_update_users_credentials"></a> [create\_lambda\_rds\_oracle\_update\_users\_credentials](#input\_create\_lambda\_rds\_oracle\_update\_users\_credentials) | Create the Lambda function lambda-rds-oracle-update-users-credentials and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_secretsmanager_rds_mysql_password_rotation"></a> [create\_lambda\_secretsmanager\_rds\_mysql\_password\_rotation](#input\_create\_lambda\_secretsmanager\_rds\_mysql\_password\_rotation) | Create the Lambda function lambda-secretsmanager-rds-mysql-password-rotation and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_secretsmanager_rds_oracle_password_rotation"></a> [create\_lambda\_secretsmanager\_rds\_oracle\_password\_rotation](#input\_create\_lambda\_secretsmanager\_rds\_oracle\_password\_rotation) | Create the Lambda function lambda-secretsmanager-rds-oracle-password-rotation and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_valkey_clear_cache"></a> [create\_lambda\_valkey\_clear\_cache](#input\_create\_lambda\_valkey\_clear\_cache) | Create the Lambda function lambda-valkey-clear-cache and its IAM role. | `bool` | `true` | no |
| <a name="input_create_namespace_platform_ops"></a> [create\_namespace\_platform\_ops](#input\_create\_namespace\_platform\_ops) | Whether to create the Kubernetes namespace 'platform-ops'. | `bool` | `false` | no |
| <a name="input_create_namespace_platform_ops_addons"></a> [create\_namespace\_platform\_ops\_addons](#input\_create\_namespace\_platform\_ops\_addons) | Whether to create the Kubernetes namespace 'platform-ops-addons'. | `bool` | `false` | no |
| <a name="input_create_namespace_platform_ops_customers"></a> [create\_namespace\_platform\_ops\_customers](#input\_create\_namespace\_platform\_ops\_customers) | Whether to create the Kubernetes namespace 'platform-ops-customers'. | `bool` | `false` | no |
| <a name="input_create_namespace_platform_ops_internal"></a> [create\_namespace\_platform\_ops\_internal](#input\_create\_namespace\_platform\_ops\_internal) | Whether to create the Kubernetes namespace 'platform-ops-internal'. | `bool` | `false` | no |
| <a name="input_create_nodepool"></a> [create\_nodepool](#input\_create\_nodepool) | Whether to create Karpenter NodePool manifests from nodepools.tf. When false, no NodePool resources are created. | `bool` | `false` | no |
| <a name="input_create_priority_class"></a> [create\_priority\_class](#input\_create\_priority\_class) | Whether to create Kubernetes PriorityClass resources from priority-classes.tf. When false, no PriorityClass resources are created. | `bool` | `false` | no |
| <a name="input_create_sg_custom"></a> [create\_sg\_custom](#input\_create\_sg\_custom) | Create the custom security group (sg-custom). | `bool` | `false` | no |
| <a name="input_create_sg_customer_ips"></a> [create\_sg\_customer\_ips](#input\_create\_sg\_customer\_ips) | Create the customer security group (customer\_ips). | `bool` | `false` | no |
| <a name="input_create_sg_internal_ips"></a> [create\_sg\_internal\_ips](#input\_create\_sg\_internal\_ips) | Create the security group that allows ingress from the managed prefix list (internal\_ips). | `bool` | `false` | no |
| <a name="input_create_step_function_dump_rds"></a> [create\_step\_function\_dump\_rds](#input\_create\_step\_function\_dump\_rds) | Feature flag to enable/disable all Step Functions state machines in this module. When false, no Step Functions are created (module for\_each becomes empty). | `bool` | `true` | no |
| <a name="input_create_step_function_version_update"></a> [create\_step\_function\_version\_update](#input\_create\_step\_function\_version\_update) | Feature flag to enable/disable all Step Functions state machines in this module. When false, no Step Functions are created (module for\_each becomes empty). | `bool` | `true` | no |
| <a name="input_create_task_definition"></a> [create\_task\_definition](#input\_create\_task\_definition) | Whether to create the ECS task definition. | `bool` | `false` | no |
| <a name="input_create_valkey"></a> [create\_valkey](#input\_create\_valkey) | Create the Valkey (ElastiCache) replication group. | `bool` | `true` | no |
| <a name="input_create_valkey_security_group"></a> [create\_valkey\_security\_group](#input\_create\_valkey\_security\_group) | Determines if a security group for Valkey is created | `bool` | `false` | no |
| <a name="input_create_valkey_subnet_group"></a> [create\_valkey\_subnet\_group](#input\_create\_valkey\_subnet\_group) | Determines whether the Elasticache subnet group for Valkey will be created or not | `bool` | `false` | no |
| <a name="input_customers_revision"></a> [customers\_revision](#input\_customers\_revision) | The revision of the customers app to monitor the platform-ops-argocd-infra repository. | `string` | `"main"` | no |
| <a name="input_ecs_on_demand_desired_capacity"></a> [ecs\_on\_demand\_desired\_capacity](#input\_ecs\_on\_demand\_desired\_capacity) | Desired capacity for the ECS on-demand Auto Scaling Group. | `number` | `1` | no |
| <a name="input_ecs_spot_desired_capacity"></a> [ecs\_spot\_desired\_capacity](#input\_ecs\_spot\_desired\_capacity) | Desired capacity for the ECS spot Auto Scaling Group. | `number` | `0` | no |
| <a name="input_eks_oidc_provider"></a> [eks\_oidc\_provider](#input\_eks\_oidc\_provider) | EKS OIDC provider URL/identifier. | `string` | n/a | yes |
| <a name="input_eks_oidc_provider_arn"></a> [eks\_oidc\_provider\_arn](#input\_eks\_oidc\_provider\_arn) | EKS OIDC provider ARN (used for IAM roles for service accounts). | `string` | n/a | yes |
| <a name="input_elasticache_security_group_id"></a> [elasticache\_security\_group\_id](#input\_elasticache\_security\_group\_id) | Security Group ID for Elasticache/Valkey. | `string` | n/a | yes |
| <a name="input_elasticache_subnet_group_name"></a> [elasticache\_subnet\_group\_name](#input\_elasticache\_subnet\_group\_name) | Subnet group name for Elasticache/Valkey. | `string` | n/a | yes |
| <a name="input_environments"></a> [environments](#input\_environments) | A list of environment names (e.g., prod, homol, test). Used to provision Karpenter NodePools per environment. | `list(string)` | <pre>[<br/>  "prod",<br/>  "homol",<br/>  "test"<br/>]</pre> | no |
| <a name="input_iam_roles"></a> [iam\_roles](#input\_iam\_roles) | IAM role input overrides merged on top of local defaults in iam.tf. Use this to override name/policies/trust/permissions or to disable a role by setting create=false. | `any` | `{}` | no |
| <a name="input_ecs_ingress_rules"></a> [ecs\_ingress\_rules](#input\_ecs\_ingress\_rules) | Ingress rules for ECS instances | <pre>list(object({<br/>    port = number<br/>    cidr = string<br/>  }))</pre> | `[]` | no |
| <a name="input_ecs_on_demand_instance_type"></a> [ecs\_on\_demand\_instance\_type](#input\_ecs\_on\_demand\_instance\_type) | Instance type for the ECS on-demand Auto Scaling Group. | `string` | `"t3.medium"` | no |
| <a name="input_ecs_root_volume_size"></a> [ecs\_root\_volume\_size](#input\_ecs\_root\_volume\_size) | Size in GiB for the root EBS volume attached to ECS cluster instances. If null, the AMI default is used. | `number` | `null` | no |
| <a name="input_ecs_spot_instance_types"></a> [ecs\_spot\_instance\_types](#input\_ecs\_spot\_instance\_types) | List of instance types for the ECS spot Auto Scaling Group. | `list(string)` | <pre>[<br/>  "t3.medium"<br/>]</pre> | no |
| <a name="input_internal_revision"></a> [internal\_revision](#input\_internal\_revision) | The revision of the internal app to monitor the platform-ops-argocd-infra repository. | `string` | `"main"` | no |
| <a name="input_lambda_layer_cryptography_arn"></a> [lambda\_layer\_cryptography\_arn](#input\_lambda\_layer\_cryptography\_arn) | ARN of the regional Lambda layer: cryptography. | `string` | `null` | no |
| <a name="input_lambda_layer_mysqldb_arn"></a> [lambda\_layer\_mysqldb\_arn](#input\_lambda\_layer\_mysqldb\_arn) | ARN of the regional Lambda layer: mysqldb. | `string` | `null` | no |
| <a name="input_lambda_layer_oracledb_arn"></a> [lambda\_layer\_oracledb\_arn](#input\_lambda\_layer\_oracledb\_arn) | ARN of the regional Lambda layer: oracledb. | `string` | n/a | yes |
| <a name="input_lambda_layer_request_arn"></a> [lambda\_layer\_request\_arn](#input\_lambda\_layer\_request\_arn) | ARN of the regional Lambda layer: request. | `string` | n/a | yes |
| <a name="input_lambda_layer_tabulate_arn"></a> [lambda\_layer\_tabulate\_arn](#input\_lambda\_layer\_tabulate\_arn) | ARN of the regional Lambda layer: tabulate. | `string` | n/a | yes |
| <a name="input_lambda_layer_valkey_client_arn"></a> [lambda\_layer\_valkey\_client\_arn](#input\_lambda\_layer\_valkey\_client\_arn) | ARN of the regional Lambda layer: valkey-client. | `string` | n/a | yes |
| <a name="input_lambda_rds_create_snapshot_arn"></a> [lambda\_rds\_create\_snapshot\_arn](#input\_lambda\_rds\_create\_snapshot\_arn) | Lambda Function ARN for regional lambda\_rds\_create\_snapshot. | `string` | n/a | yes |
| <a name="input_lambda_rds_delete_instance_arn"></a> [lambda\_rds\_delete\_instance\_arn](#input\_lambda\_rds\_delete\_instance\_arn) | Lambda Function ARN for regional lambda\_rds\_delete\_instance. | `string` | n/a | yes |
| <a name="input_lambda_rds_delete_snapshot_arn"></a> [lambda\_rds\_delete\_snapshot\_arn](#input\_lambda\_rds\_delete\_snapshot\_arn) | Lambda Function ARN for regional lambda\_rds\_delete\_snapshot. | `string` | n/a | yes |
| <a name="input_lambda_rds_modify_instance_arn"></a> [lambda\_rds\_modify\_instance\_arn](#input\_lambda\_rds\_modify\_instance\_arn) | Lambda Function ARN for regional lambda\_rds\_modify\_instance. | `string` | n/a | yes |
| <a name="input_lambda_rds_modify_instance_version_update_arn"></a> [lambda\_rds\_modify\_instance\_version\_update\_arn](#input\_lambda\_rds\_modify\_instance\_version\_update\_arn) | Lambda Function ARN for regional lambda\_rds\_modify\_instance\_version\_update. | `string` | n/a | yes |
| <a name="input_lambda_rds_restore_snapshot_arn"></a> [lambda\_rds\_restore\_snapshot\_arn](#input\_lambda\_rds\_restore\_snapshot\_arn) | Lambda Function ARN for regional lambda\_rds\_restore\_snapshot. | `string` | n/a | yes |
| <a name="input_lambda_rds_status_check_arn"></a> [lambda\_rds\_status\_check\_arn](#input\_lambda\_rds\_status\_check\_arn) | Lambda Function ARN for regional lambda\_rds\_status\_check. | `string` | n/a | yes |
| <a name="input_ecs_on_demand_max_size"></a> [ecs\_on\_demand\_max\_size](#input\_ecs\_on\_demand\_max\_size) | Maximum size for the ECS on-demand Auto Scaling Group. | `number` | `4` | no |
| <a name="input_ecs_on_demand_min_size"></a> [ecs\_on\_demand\_min\_size](#input\_ecs\_on\_demand\_min\_size) | Minimum size for the ECS on-demand Auto Scaling Group. | `number` | `0` | no |
| <a name="input_ecs_spot_max_size"></a> [ecs\_spot\_max\_size](#input\_ecs\_spot\_max\_size) | Maximum size for the ECS spot Auto Scaling Group. | `number` | `4` | no |
| <a name="input_ecs_spot_min_size"></a> [ecs\_spot\_min\_size](#input\_ecs\_spot\_min\_size) | Minimum size for the ECS spot Auto Scaling Group. | `number` | `0` | no |
| <a name="input_namespaces"></a> [namespaces](#input\_namespaces) | Kubernetes namespace overrides/additions keyed by logical id. Merged on top of local defaults in namespace.tf. Set create=false to disable a namespace. | `any` | `{}` | no |
| <a name="input_nodepools"></a> [nodepools](#input\_nodepools) | NodePool manifest overrides/additions keyed by nodepool name. Merged on top of local defaults in nodepools.tf. | `any` | `{}` | no |
| <a name="input_priority_classes"></a> [priority\_classes](#input\_priority\_classes) | Kubernetes PriorityClass overrides/additions keyed by logical id. Merged on top of local defaults in priority-class.tf. Each value should include at least 'value' (number) and optionally 'metadata.name', 'global\_default', 'preemption\_policy', 'description'. | `any` | `{}` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnet IDs used for VPC-attached Lambdas. | `list(string)` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | Private subnets for ECS instances | `list(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | `"us-east-1"` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Resource prefix for AWS Core resources. Needs to be unique per AWS (sub) account. | `string` | n/a | yes |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | Security Group module input overrides merged on top of local defaults in security-groups.tf. Use this to override name/description/ingress/egress/tags or to disable a SG by setting create=false. | `any` | `{}` | no |
| <a name="input_sg_custom_ips"></a> [sg\_custom\_ips](#input\_sg\_custom\_ips) | Comma-separated CIDR blocks allowed to reach Oracle (1521) and MySQL (3306) through sg-custom. Example: '1.2.3.4/32,5.6.7.8/32'. | `string` | `""` | no |
| <a name="input_sg_customer_ips_list"></a> [sg\_customer\_ips\_list](#input\_sg\_customer\_ips\_list) | CIDR blocks allowed as ingress on customer\_ips (all protocols/ports). Starts empty and can be expanded when the customer provides IPs. | `list(string)` | `[]` | no |
| <a name="input_sg_internal_ips_list"></a> [sg\_internal\_ips\_list](#input\_sg\_internal\_ips\_list) | Additional CIDR blocks allowed as ingress (all protocols/ports). Example: ['1.2.3.4/32','5.6.7.8/32']. | `list(string)` | `[]` | no |
| <a name="input_step_functions"></a> [step\_functions](#input\_step\_functions) | Step Functions module input overrides merged on top of local defaults in step-functions.tf. Use this to override name/definition/logging/timeouts or to disable a state machine by setting create=false. | `any` | `{}` | no |
| <a name="input_sync_windows_ops"></a> [sync\_windows\_ops](#input\_sync\_windows\_ops) | ArgoCD sync windows for the platform-ops projects. | <pre>list(object({<br/>    kind         = optional(string, "allow")<br/>    schedule     = optional(string, "0 12 * * 1")<br/>    duration     = optional(string, "1h")<br/>    timeZone     = optional(string, "")<br/>    manualSync   = optional(bool, true)<br/>    namespaces   = optional(list(string), ["*"])<br/>    clusters     = optional(list(string), ["*"])<br/>    applications = optional(list(string), ["*"])<br/>  }))</pre> | `[]` | no |
| <a name="input_sync_windows_ops_customers"></a> [sync\_windows\_ops\_customers](#input\_sync\_windows\_ops\_customers) | ArgoCD sync windows for the platform-ops-customers project. | <pre>list(object({<br/>    kind         = optional(string, "allow")<br/>    schedule     = optional(string, "0 12 * * 1")<br/>    duration     = optional(string, "1h")<br/>    timeZone     = optional(string, "")<br/>    manualSync   = optional(bool, true)<br/>    namespaces   = optional(list(string), ["*"])<br/>    clusters     = optional(list(string), ["*"])<br/>    applications = optional(list(string), ["*"])<br/>  }))</pre> | <pre>[<br/>  {<br/>    "applications": [<br/>      "*"<br/>    ],<br/>    "clusters": [<br/>      "*"<br/>    ],<br/>    "duration": "1h",<br/>    "kind": "allow",<br/>    "manualSync": true,<br/>    "namespaces": [<br/>      "*"<br/>    ],<br/>    "schedule": "0 12 * * 1",<br/>    "timeZone": ""<br/>  }<br/>]</pre> | no |
| <a name="input_sync_windows_ops_internal"></a> [sync\_windows\_ops\_internal](#input\_sync\_windows\_ops\_internal) | ArgoCD sync windows for the platform-ops-internal project. | <pre>list(object({<br/>    kind         = optional(string, "allow")<br/>    schedule     = optional(string, "0 12 * * 1")<br/>    duration     = optional(string, "1h")<br/>    timeZone     = optional(string, "")<br/>    manualSync   = optional(bool, true)<br/>    namespaces   = optional(list(string), ["*"])<br/>    clusters     = optional(list(string), ["*"])<br/>    applications = optional(list(string), ["*"])<br/>  }))</pre> | <pre>[<br/>  {<br/>    "applications": [<br/>      "*"<br/>    ],<br/>    "clusters": [<br/>      "*"<br/>    ],<br/>    "duration": "1h",<br/>    "kind": "allow",<br/>    "manualSync": true,<br/>    "namespaces": [<br/>      "*"<br/>    ],<br/>    "schedule": "0 12 * * 1",<br/>    "timeZone": ""<br/>  }<br/>]</pre> | no |
| <a name="input_valkey_engine_version"></a> [valkey\_engine\_version](#input\_valkey\_engine\_version) | Valkey engine version used by ElastiCache. | `string` | `"8.0"` | no |
| <a name="input_valkey_maintenance_window"></a> [valkey\_maintenance\_window](#input\_valkey\_maintenance\_window) | Maintenance window for Valkey (UTC). Example: 'Mon:00:00-Mon:03:00'. | `string` | `"sun:00:00-sun:04:00"` | no |
| <a name="input_valkey_multi_az"></a> [valkey\_multi\_az](#input\_valkey\_multi\_az) | Enable Multi-AZ for Valkey. When true, two cache clusters are created with automatic failover enabled. | `bool` | `false` | no |
| <a name="input_valkey_node_type"></a> [valkey\_node\_type](#input\_valkey\_node\_type) | ElastiCache node type for Valkey (e.g., cache.t4g.small). | `string` | `"cache.t3.small"` | no |
| <a name="input_valkeys"></a> [valkeys](#input\_valkeys) | Valkey/ElastiCache module input overrides merged on top of local defaults in valkey.tf. Use this to override module inputs or to disable a cluster by setting create=false. | `any` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where cluster resources are deployed. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_name"></a> [autoscaling\_group\_name](#output\_autoscaling\_group\_name) | n/a |
| <a name="output_cloud_map_namespace_arn"></a> [cloud\_map\_namespace\_arn](#output\_cloud\_map\_namespace\_arn) | n/a |
| <a name="output_cloud_map_namespace_id"></a> [cloud\_map\_namespace\_id](#output\_cloud\_map\_namespace\_id) | n/a |
| <a name="output_cloud_map_namespace_name"></a> [cloud\_map\_namespace\_name](#output\_cloud\_map\_namespace\_name) | n/a |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | n/a |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_elasticache_valkey"></a> [elasticache\_valkey](#output\_elasticache\_valkey) | n/a |
| <a name="output_elasticache_valkey_all"></a> [elasticache\_valkey\_all](#output\_elasticache\_valkey\_all) | All Valkey module instances (keyed by valkeys map key) |
| <a name="output_iam_roles"></a> [iam\_roles](#output\_iam\_roles) | n/a |
| <a name="output_lambda_rds_oracle_execute_sql_statements"></a> [lambda\_rds\_oracle\_execute\_sql\_statements](#output\_lambda\_rds\_oracle\_execute\_sql\_statements) | n/a |
| <a name="output_lambda_rds_oracle_update_users_credentials"></a> [lambda\_rds\_oracle\_update\_users\_credentials](#output\_lambda\_rds\_oracle\_update\_users\_credentials) | n/a |
| <a name="output_lambda_secretsmanager_rds_mysql_password_rotation"></a> [lambda\_secretsmanager\_rds\_mysql\_password\_rotation](#output\_lambda\_secretsmanager\_rds\_mysql\_password\_rotation) | n/a |
| <a name="output_lambda_secretsmanager_rds_oracle_password_rotation"></a> [lambda\_secretsmanager\_rds\_oracle\_password\_rotation](#output\_lambda\_secretsmanager\_rds\_oracle\_password\_rotation) | n/a |
| <a name="output_lambda_valkey_clear_cache"></a> [lambda\_valkey\_clear\_cache](#output\_lambda\_valkey\_clear\_cache) | n/a |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | n/a |
| <a name="output_security_groups"></a> [security\_groups](#output\_security\_groups) | n/a |
| <a name="output_step_functions"></a> [step\_functions](#output\_step\_functions) | n/a |
<!-- END_TF_DOCS -->