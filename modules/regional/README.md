# core-infra — regional

Deploys **region-level** resources shared by all VPCs within a given AWS account + region.

This module runs **once per AWS account + region** and creates the foundational networking, storage, database configurations, Lambda functions, and notification infrastructure. In the caller repo (`tofu-aws-infra`), each region gets its own OpenTofu state (`core-regional`), enabling multi-region expansion by simply adding a new state — without affecting the global or VPC-scoped layers.

## What this module creates

| Resource | Description | Feature flag |
|---|---|---|
| **VPC** | Network foundation with public, private, and database subnets, NAT/IGW | `create_vpc` |
| **S3 Buckets** | Temporary storage for Lambda layers and user-defined buckets | `create_s3` |
| **RDS Option Groups** | Pre-configured for Oracle SE2 19 (timezone, JVM, S3 integration) | `create_rds_option_groups` |
| **RDS Parameter Groups** | Tuned for Oracle SE2 19 per instance class (t3.medium/large/xlarge) | `create_rds_parameter_groups` |
| **Secrets Manager** | AppServer environment secrets | `create_secrets_manager` |
| **Lambda Functions (8)** | RDS lifecycle: create/delete/restore snapshot, start/stop, modify, status check, version update | `create_lambda_rds_*` |
| **Lambda Layers (6)** | Shared libraries: oracledb, mysqldb, request, tabulate, valkey-client, cryptography | `create_layer_*` |
| **WAF** | Web ACL with AWS Managed Rules (SQLi, bad inputs, admin protection) | `create_waf` |
| **SNS Notifications** | Alert topic with email subscriptions and KMS event rules | `create_sns_topic`, `enable_kms_*_alert` |
| **SSM Jumpbox** | Auto Scaling Group for bastion instances with Session Manager access | `create_ssm_jumpbox` |

## Usage

```hcl
module "core_regional" {
  source = "git::https://github.com/augustovoigt/tofu-aws-core-infra.git//modules/regional?ref=<tag>"

  aws_region      = "us-east-1"
  aws_account_id  = "123456789012"
  resource_prefix = "myproject"

  # IAM roles from global module
  iam_role_rds_enhanced_monitoring_arn = module.core_global.iam_roles.rds_enhanced_monitoring.arn
  iam_role_rds_s3_integration_arn      = module.core_global.iam_roles.rds_s3_integration.arn

  # S3
  create_s3 = true

  # RDS
  create_rds_option_groups    = true
  create_rds_parameter_groups = true

  # VPC (for ECS deployments)
  create_vpc         = true
  vpc_cidr           = "10.80.176.0/20"
  enable_nat_gateway = true
  single_nat_gateway = true
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.31.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eventbridge_notifications"></a> [eventbridge\_notifications](#module\_eventbridge\_notifications) | terraform-aws-modules/eventbridge/aws | 4.3.0 |
| <a name="module_lambda_rds_create_snapshot"></a> [lambda\_rds\_create\_snapshot](#module\_lambda\_rds\_create\_snapshot) | ./modules/lambdas/lambda-rds-create-snapshot | n/a |
| <a name="module_lambda_rds_delete_instance"></a> [lambda\_rds\_delete\_instance](#module\_lambda\_rds\_delete\_instance) | ./modules/lambdas/lambda-rds-delete-instance | n/a |
| <a name="module_lambda_rds_delete_snapshot"></a> [lambda\_rds\_delete\_snapshot](#module\_lambda\_rds\_delete\_snapshot) | ./modules/lambdas/lambda-rds-delete-snapshot | n/a |
| <a name="module_lambda_rds_modify_instance"></a> [lambda\_rds\_modify\_instance](#module\_lambda\_rds\_modify\_instance) | ./modules/lambdas/lambda-rds-modify-instance | n/a |
| <a name="module_lambda_rds_modify_instance_version_update"></a> [lambda\_rds\_modify\_instance\_version\_update](#module\_lambda\_rds\_modify\_instance\_version\_update) | ./modules/lambdas/lambda-rds-modify-instance-version-update | n/a |
| <a name="module_lambda_rds_restore_snapshot"></a> [lambda\_rds\_restore\_snapshot](#module\_lambda\_rds\_restore\_snapshot) | ./modules/lambdas/lambda-rds-restore-snapshot | n/a |
| <a name="module_lambda_rds_start_stop_instance"></a> [lambda\_rds\_start\_stop\_instance](#module\_lambda\_rds\_start\_stop\_instance) | ./modules/lambdas/lambda-rds-start-stop-instance | n/a |
| <a name="module_lambda_rds_status_check"></a> [lambda\_rds\_status\_check](#module\_lambda\_rds\_status\_check) | ./modules/lambdas/lambda-rds-status-check | n/a |
| <a name="module_layer_cryptography"></a> [layer\_cryptography](#module\_layer\_cryptography) | ./modules/lambdas/layer-cryptography | n/a |
| <a name="module_layer_mysqldb"></a> [layer\_mysqldb](#module\_layer\_mysqldb) | ./modules/lambdas/layer-mysqldb | n/a |
| <a name="module_layer_oracledb"></a> [layer\_oracledb](#module\_layer\_oracledb) | ./modules/lambdas/layer-oracledb | n/a |
| <a name="module_layer_request"></a> [layer\_request](#module\_layer\_request) | ./modules/lambdas/layer-request | n/a |
| <a name="module_layer_tabulate"></a> [layer\_tabulate](#module\_layer\_tabulate) | ./modules/lambdas/layer-tabulate | n/a |
| <a name="module_layer_valkey_client"></a> [layer\_valkey\_client](#module\_layer\_valkey\_client) | ./modules/lambdas/layer-valkey-client | n/a |
| <a name="module_option_group"></a> [option\_group](#module\_option\_group) | terraform-aws-modules/rds/aws//modules/db_option_group | 7.1.0 |
| <a name="module_parameter_group"></a> [parameter\_group](#module\_parameter\_group) | terraform-aws-modules/rds/aws//modules/db_parameter_group | 7.1.0 |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | 5.10.0 |
| <a name="module_sns_topic"></a> [sns\_topic](#module\_sns\_topic) | terraform-aws-modules/sns/aws | 7.1.0 |
| <a name="module_ssm_jumpbox"></a> [ssm\_jumpbox](#module\_ssm\_jumpbox) | ./modules/vpc/ssm-jumpbox | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 6.0.0 |
| <a name="module_vpc-services"></a> [vpc-services](#module\_vpc-services) | ./modules/vpc/services | n/a |
| <a name="module_vpc_gateway_endpoints"></a> [vpc\_gateway\_endpoints](#module\_vpc\_gateway\_endpoints) | terraform-aws-modules/vpc/aws//modules/vpc-endpoints | 6.6.0 |
| <a name="module_waf"></a> [waf](#module\_waf) | git::https://github.com/augustovoigt/tofu-aws-modules.git//modules/aws/waf | v1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_s3_object.lambda_layers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_autoscaling_group.ssm_jumpbox](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_iam_instance_profile.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.ssm_jumpbox](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.ssm_jumpbox](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.ssm_jumpbox](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_default_tags.provider_tags](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_ebs_default_kms_key.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ebs_default_kms_key) | data source |
| [aws_ec2_instance_type.ssm_jumpbox](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID for resource provisioning. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region where resources will be provisioned. | `string` | n/a | yes |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Controls if database subnet group should be created (n.b. database\_subnets must also be set) | `bool` | `false` | no |
| <a name="input_create_igw"></a> [create\_igw](#input\_create\_igw) | Controls if an Internet Gateway is created for public subnets and the related routes that connect them | `bool` | `false` | no |
| <a name="input_create_lambda_rds_create_snapshot"></a> [create\_lambda\_rds\_create\_snapshot](#input\_create\_lambda\_rds\_create\_snapshot) | Create the Lambda function lambda-rds-create-snapshot and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_delete_instance"></a> [create\_lambda\_rds\_delete\_instance](#input\_create\_lambda\_rds\_delete\_instance) | Create the Lambda function lambda-rds-delete-instance and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_delete_snapshot"></a> [create\_lambda\_rds\_delete\_snapshot](#input\_create\_lambda\_rds\_delete\_snapshot) | Create the Lambda function lambda-rds-delete-snapshot and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_modify_instance"></a> [create\_lambda\_rds\_modify\_instance](#input\_create\_lambda\_rds\_modify\_instance) | Create the Lambda function lambda-rds-modify-instance and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_modify_instance_version_update"></a> [create\_lambda\_rds\_modify\_instance\_version\_update](#input\_create\_lambda\_rds\_modify\_instance\_version\_update) | Create the Lambda function lambda-rds-modify-instance-version-update and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_restore_snapshot"></a> [create\_lambda\_rds\_restore\_snapshot](#input\_create\_lambda\_rds\_restore\_snapshot) | Create the Lambda function lambda-rds-restore-snapshot and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_start_stop_instance"></a> [create\_lambda\_rds\_start\_stop\_instance](#input\_create\_lambda\_rds\_start\_stop\_instance) | Create the Lambda function lambda-rds-start-stop-instance and its IAM role. | `bool` | `true` | no |
| <a name="input_create_lambda_rds_status_check"></a> [create\_lambda\_rds\_status\_check](#input\_create\_lambda\_rds\_status\_check) | Create the Lambda function lambda-rds-status-check and its IAM role. | `bool` | `true` | no |
| <a name="input_create_layer_cryptography"></a> [create\_layer\_cryptography](#input\_create\_layer\_cryptography) | Create the Lambda layer layer-cryptography. | `bool` | `true` | no |
| <a name="input_create_layer_mysqldb"></a> [create\_layer\_mysqldb](#input\_create\_layer\_mysqldb) | Create the Lambda layer layer-mysqldb. | `bool` | `true` | no |
| <a name="input_create_layer_oracledb"></a> [create\_layer\_oracledb](#input\_create\_layer\_oracledb) | Create the Lambda layer layer-oracledb. | `bool` | `true` | no |
| <a name="input_create_layer_request"></a> [create\_layer\_request](#input\_create\_layer\_request) | Create the Lambda layer layer-request. | `bool` | `true` | no |
| <a name="input_create_layer_tabulate"></a> [create\_layer\_tabulate](#input\_create\_layer\_tabulate) | Create the Lambda layer layer-tabulate. | `bool` | `true` | no |
| <a name="input_create_layer_valkey_client"></a> [create\_layer\_valkey\_client](#input\_create\_layer\_valkey\_client) | Create the Lambda layer layer-valkey-client. | `bool` | `true` | no |
| <a name="input_create_rds_option_groups"></a> [create\_rds\_option\_groups](#input\_create\_rds\_option\_groups) | Create RDS option groups. | `bool` | `true` | no |
| <a name="input_create_rds_parameter_groups"></a> [create\_rds\_parameter\_groups](#input\_create\_rds\_parameter\_groups) | Create RDS parameter groups. | `bool` | `true` | no |
| <a name="input_create_s3"></a> [create\_s3](#input\_create\_s3) | Create S3 buckets and supporting objects used by this module (e.g., bucket for lambda layers). | `bool` | `true` | no |
| <a name="input_create_secrets_manager"></a> [create\_secrets\_manager](#input\_create\_secrets\_manager) | Create AWS Secrets Manager secrets managed by this module. | `bool` | `true` | no |
| <a name="input_create_sns_topic"></a> [create\_sns\_topic](#input\_create\_sns\_topic) | Create SNS topic for notifications. | `bool` | `false` | no |
| <a name="input_create_ssm_jumpbox"></a> [create\_ssm\_jumpbox](#input\_create\_ssm\_jumpbox) | Enable or disable the creation of the SSM jumpbox resources. | `bool` | `false` | no |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Controls if VPC should be created (it affects almost all resources) | `bool` | `false` | no |
| <a name="input_create_waf"></a> [create\_waf](#input\_create\_waf) | Create AWS WAF resources (using tofu-aws-modules WAF module). | `bool` | `false` | no |
| <a name="input_enable_kms_deletion_alert"></a> [enable\_kms\_deletion\_alert](#input\_enable\_kms\_deletion\_alert) | Enable alert for KMS key scheduled for deletion. | `bool` | `false` | no |
| <a name="input_enable_kms_disabled_alert"></a> [enable\_kms\_disabled\_alert](#input\_enable\_kms\_disabled\_alert) | Enable alert for KMS key being disabled. | `bool` | `false` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Should be true if you want to provision NAT Gateways for each of your private networks | `bool` | `false` | no |
| <a name="input_environments"></a> [environments](#input\_environments) | A list of environment names (e.g., prod, homol, test) deployed in this infrastructure. Used to provision resources per environment. | `list(string)` | <pre>[<br/>  "prod",<br/>  "homol",<br/>  "test"<br/>]</pre> | no |
| <a name="input_eventbridge_role_name"></a> [eventbridge\_role\_name](#input\_eventbridge\_role\_name) | Optional fixed EventBridge IAM role name used by notification rules. If empty, a default name is generated. | `string` | `""` | no |
| <a name="input_gateway_endpoints"></a> [gateway\_endpoints](#input\_gateway\_endpoints) | List of services to create VPC Gateway endpoints for. | `list(string)` | <pre>[<br/>  "s3"<br/>]</pre> | no |
| <a name="input_iam_role_rds_enhanced_monitoring_arn"></a> [iam\_role\_rds\_enhanced\_monitoring\_arn](#input\_iam\_role\_rds\_enhanced\_monitoring\_arn) | IAM Role ARN for RDS Enhanced Monitoring. Required when create\_lambda\_rds\_modify\_instance=true. | `string` | `null` | no |
| <a name="input_iam_role_rds_s3_integration_arn"></a> [iam\_role\_rds\_s3\_integration\_arn](#input\_iam\_role\_rds\_s3\_integration\_arn) | IAM Role ARN for RDS S3 integration. Required when create\_lambda\_rds\_modify\_instance=true. | `string` | `null` | no |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | Controls if instances launched in the public subnets should receive a public IP address. | `bool` | `false` | no |
| <a name="input_notifications_eventbridge_rules"></a> [notifications\_eventbridge\_rules](#input\_notifications\_eventbridge\_rules) | Additional/override EventBridge rules map (merged on top of the defaults when enabled). | `any` | `{}` | no |
| <a name="input_notifications_eventbridge_targets"></a> [notifications\_eventbridge\_targets](#input\_notifications\_eventbridge\_targets) | Additional/override EventBridge targets map (merged on top of the defaults when enabled). | `any` | `{}` | no |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs` | `bool` | `false` | no |
| <a name="input_rds_option_groups"></a> [rds\_option\_groups](#input\_rds\_option\_groups) | Map of option groups to create. Keys are logical identifiers; values define name/engine/options. | `any` | `{}` | no |
| <a name="input_rds_parameter_groups"></a> [rds\_parameter\_groups](#input\_rds\_parameter\_groups) | Map of parameter groups to create. Keys are logical identifiers; values define name/family/parameters. | `any` | `{}` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Resource prefix for AWS Core resources. Needs to be unique per AWS (sub) account. | `string` | n/a | yes |
| <a name="input_s3_buckets"></a> [s3\_buckets](#input\_s3\_buckets) | Map of S3 buckets to create. Keys are logical identifiers; values are passed into terraform-aws-modules/s3-bucket. | `any` | `{}` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | `bool` | `false` | no |
| <a name="input_sns_topic_arn_override"></a> [sns\_topic\_arn\_override](#input\_sns\_topic\_arn\_override) | Use an existing SNS Topic ARN if not creating one with Terraform. | `string` | `""` | no |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | Name of the SNS topic. | `string` | `"platform-ops-notifications"` | no |
| <a name="input_sns_topic_subscription_email"></a> [sns\_topic\_subscription\_email](#input\_sns\_topic\_subscription\_email) | Email address to subscribe to the notifications SNS topic. | `string` | `""` | no |
| <a name="input_sns_topic_subscriptions"></a> [sns\_topic\_subscriptions](#input\_sns\_topic\_subscriptions) | Optional SNS subscriptions map passed to terraform-aws-modules/sns. When set (non-empty), it overrides sns\_topic\_subscription\_email. | <pre>map(object({<br/>    protocol = string<br/>    endpoint = string<br/>  }))</pre> | `{}` | no |
| <a name="input_ssm_jumpbox_desired_capacity"></a> [ssm\_jumpbox\_desired\_capacity](#input\_ssm\_jumpbox\_desired\_capacity) | Desired number of SSM jumpbox instances. Set to 1 to launch, 0 to terminate. | `number` | `1` | no |
| <a name="input_ssm_jumpbox_instance_type"></a> [ssm\_jumpbox\_instance\_type](#input\_ssm\_jumpbox\_instance\_type) | The EC2 instance type for the SSM jumpbox. | `string` | `"t4g.micro"` | no |
| <a name="input_app_env_secrets"></a> [appserver\_env\_secrets](#input\_appserver\_env\_secrets) | Per-environment Secrets Manager secret configuration overrides for the AppServer credentials. Merged on top of defaults in secrets-manager.tf. | `any` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC subnet in CIDR notation. | `string` | `""` | no |
| <a name="input_waf"></a> [waf](#input\_waf) | WAF module input overrides. Merged on top of the defaults defined in waf.tf locals. | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_database_security_group"></a> [aws\_database\_security\_group](#output\_aws\_database\_security\_group) | AWS database security group |
| <a name="output_aws_service_base_security_group"></a> [aws\_service\_base\_security\_group](#output\_aws\_service\_base\_security\_group) | AWS service base security group |
| <a name="output_database_route_table_ids"></a> [database\_route\_table\_ids](#output\_database\_route\_table\_ids) | Database subnet route table IDs |
| <a name="output_database_subnets"></a> [database\_subnets](#output\_database\_subnets) | Database subnet IDs |
| <a name="output_default_security_group_id"></a> [default\_security\_group\_id](#output\_default\_security\_group\_id) | n/a |
| <a name="output_igw_arn"></a> [igw\_arn](#output\_igw\_arn) | The ARN of the Internet Gateway |
| <a name="output_igw_id"></a> [igw\_id](#output\_igw\_id) | The ID of the Internet Gateway |
| <a name="output_lambda_rds_create_snapshot"></a> [lambda\_rds\_create\_snapshot](#output\_lambda\_rds\_create\_snapshot) | n/a |
| <a name="output_lambda_rds_delete_instance"></a> [lambda\_rds\_delete\_instance](#output\_lambda\_rds\_delete\_instance) | n/a |
| <a name="output_lambda_rds_delete_snapshot"></a> [lambda\_rds\_delete\_snapshot](#output\_lambda\_rds\_delete\_snapshot) | n/a |
| <a name="output_lambda_rds_modify_instance"></a> [lambda\_rds\_modify\_instance](#output\_lambda\_rds\_modify\_instance) | n/a |
| <a name="output_lambda_rds_modify_instance_version_update"></a> [lambda\_rds\_modify\_instance\_version\_update](#output\_lambda\_rds\_modify\_instance\_version\_update) | n/a |
| <a name="output_lambda_rds_restore_snapshot"></a> [lambda\_rds\_restore\_snapshot](#output\_lambda\_rds\_restore\_snapshot) | n/a |
| <a name="output_lambda_rds_start_stop_instance"></a> [lambda\_rds\_start\_stop\_instance](#output\_lambda\_rds\_start\_stop\_instance) | n/a |
| <a name="output_lambda_rds_status_check"></a> [lambda\_rds\_status\_check](#output\_lambda\_rds\_status\_check) | n/a |
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
| <a name="output_ssm_jumpbox_autoscaling_group_name"></a> [ssm\_jumpbox\_autoscaling\_group\_name](#output\_ssm\_jumpbox\_autoscaling\_group\_name) | SSM jumpbox autoscaling group name |
| <a name="output_ssm_jumpbox_launch_template_id"></a> [ssm\_jumpbox\_launch\_template\_id](#output\_ssm\_jumpbox\_launch\_template\_id) | SSM jumpbox launch template ID |
| <a name="output_ssm_jumpbox_security_group"></a> [ssm\_jumpbox\_security\_group](#output\_ssm\_jumpbox\_security\_group) | SSM jumpbox security group |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | VPC CIDR block |
| <a name="output_vpc_endpoints"></a> [vpc\_endpoints](#output\_vpc\_endpoints) | VPC endpoints created. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID |
<!-- END_TF_DOCS -->