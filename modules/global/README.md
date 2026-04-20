# core-infra — global

Deploys **account-level** resources shared across all regions and VPCs.

This module runs **once per AWS account** and creates global IAM roles consumed by the regional and VPC-scoped modules. In the caller repo (`tofu-aws-infra`), it maps to a dedicated OpenTofu state (`core-global`), keeping account-wide resources isolated from region or VPC changes — so expanding to new regions or VPCs never triggers a plan here.

## What this module creates

| Resource | Description | Feature flag |
|---|---|---|
| **IAM Role — EventBridge Scheduler** | Allows EventBridge Scheduler to invoke Lambdas and Step Functions | `create_iam_role_eventbridge_scheduler` |
| **IAM Role — RDS Enhanced Monitoring** | Monitoring role for RDS instances | `create_iam_role_rds_enhanced_monitoring` |
| **IAM Role — RDS S3 Integration** | Allows RDS to export/backup to S3 | `create_iam_role_rds_s3_integration` |
| **IAM Role — Cross-Account FinOps** | Read-only role for FinOps AWS account | `create_iam_role_cross_account_finops` |

## Usage

```hcl
module "core_global" {
  source = "git::https://github.com/augustovoigt/tofu-aws-core-infra.git//modules/global?ref=<tag>"

  aws_region      = "us-east-1"
  aws_account_id  = "123456789012"
  resource_prefix = "myproject"

  create_iam_role_eventbridge_scheduler   = true
  create_iam_role_rds_enhanced_monitoring = true
  create_iam_role_rds_s3_integration      = true
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.8.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.31.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_roles"></a> [iam\_roles](#module\_iam\_roles) | terraform-aws-modules/iam/aws//modules/iam-role | 6.4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID for resource provisioning. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region where resources will be provisioned. | `string` | n/a | yes |
| <a name="input_create_iam_role_cross_account_finops"></a> [create\_iam\_role\_cross\_account\_finops](#input\_create\_iam\_role\_cross\_account\_finops) | Create the IAM role to grant read only access to the FinOps AWS account. | `bool` | `false` | no |
| <a name="input_create_iam_role_eventbridge_scheduler"></a> [create\_iam\_role\_eventbridge\_scheduler](#input\_create\_iam\_role\_eventbridge\_scheduler) | Create the IAM Role for the Eventbridge Scheduler. | `bool` | `true` | no |
| <a name="input_create_iam_role_rds_enhanced_monitoring"></a> [create\_iam\_role\_rds\_enhanced\_monitoring](#input\_create\_iam\_role\_rds\_enhanced\_monitoring) | Create the IAM Role for Enhanced Monitoring. | `bool` | `true` | no |
| <a name="input_create_iam_role_rds_s3_integration"></a> [create\_iam\_role\_rds\_s3\_integration](#input\_create\_iam\_role\_rds\_s3\_integration) | Create the IAM Role to integrate the RDS with central S3 bucket. | `bool` | `true` | no |
| <a name="input_iam_roles"></a> [iam\_roles](#input\_iam\_roles) | IAM role definitions to merge with the module defaults (local.iam\_default\_roles). Values in var.iam\_roles override defaults on key conflicts. | `map(any)` | `{}` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Resource prefix for AWS Core resources. Needs to be unique per AWS (sub) account. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_roles"></a> [iam\_roles](#output\_iam\_roles) | n/a |
<!-- END_TF_DOCS -->