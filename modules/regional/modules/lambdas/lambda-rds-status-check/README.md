## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lambda_rds_snapshot_create"></a> [lambda\_rds\_snapshot\_create](#module\_lambda\_rds\_snapshot\_create) | terraform-aws-modules/lambda/aws | ~> 7.0 |

## Resources

| Name | Type |
|------|------|
| [archive_file.lambda_rds_snapshot_create](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | ARN of the IAM Role that will be used by the Lambda function to create RDS snapshots | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_rds_snapshot_create"></a> [lambda\_rds\_snapshot\_create](#output\_lambda\_rds\_snapshot\_create) | Output for lambda\_rds\_snapshot\_create |

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_role_lambda_rds_status_check"></a> [iam\_role\_lambda\_rds\_status\_check](#module\_iam\_role\_lambda\_rds\_status\_check) | terraform-aws-modules/iam/aws//modules/iam-role | 6.4.0 |
| <a name="module_lambda_rds_status_check"></a> [lambda\_rds\_status\_check](#module\_lambda\_rds\_status\_check) | terraform-aws-modules/lambda/aws | ~> 8.0 |

## Resources

| Name | Type |
|------|------|
| [archive_file.lambda_rds_status_check](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | The AWS account ID where the Lambda function will be deployed | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region where the Lambda function will be deployed | `string` | n/a | yes |
| <a name="input_create_lambda_function"></a> [create\_lambda\_function](#input\_create\_lambda\_function) | Enable or disable the creation of the Lambda function | `bool` | `false` | no |
| <a name="input_create_lambda_function_iam_role"></a> [create\_lambda\_function\_iam\_role](#input\_create\_lambda\_function\_iam\_role) | Enable or disable the creation of the IAM role for the Lambda function | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_role_lambda_rds_status_check"></a> [iam\_role\_lambda\_rds\_status\_check](#output\_iam\_role\_lambda\_rds\_status\_check) | n/a |
| <a name="output_lambda_rds_status_check"></a> [lambda\_rds\_status\_check](#output\_lambda\_rds\_status\_check) | n/a |
<!-- END_TF_DOCS -->