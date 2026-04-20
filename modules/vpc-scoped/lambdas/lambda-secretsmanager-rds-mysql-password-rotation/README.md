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
| <a name="module_iam_role_lambda_secretsmanager_rds_mysql_password_rotation"></a> [iam\_role\_lambda\_secretsmanager\_rds\_mysql\_password\_rotation](#module\_iam\_role\_lambda\_secretsmanager\_rds\_mysql\_password\_rotation) | terraform-aws-modules/iam/aws//modules/iam-role | 6.4.0 |
| <a name="module_lambda_secretsmanager_rds_mysql_password_rotation"></a> [lambda\_secretsmanager\_rds\_mysql\_password\_rotation](#module\_lambda\_secretsmanager\_rds\_mysql\_password\_rotation) | terraform-aws-modules/lambda/aws | ~> 8.0 |

## Resources

| Name | Type |
|------|------|
| [archive_file.lambda_secretsmanager_rds_mysql_password_rotation](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | The AWS account ID where the Lambda function will be deployed | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region | `string` | n/a | yes |
| <a name="input_create_lambda_function"></a> [create\_lambda\_function](#input\_create\_lambda\_function) | Enable or disable the creation of the Lambda function | `bool` | `false` | no |
| <a name="input_create_lambda_function_iam_role"></a> [create\_lambda\_function\_iam\_role](#input\_create\_lambda\_function\_iam\_role) | Enable or disable the creation of the IAM role for the Lambda function | `bool` | `false` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix uniquely identifies Platform AWS resources. Needs to be unique per AWS (sub) account. | `string` | n/a | yes |
| <a name="input_lambda_layers"></a> [lambda\_layers](#input\_lambda\_layers) | List of AWS Lambda layer ARNs to attach to the function | `list(string)` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs where the Lambda function should be deployed | `list(string)` | n/a | yes |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of security group IDs to assign to the Lambda function within the VPC | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_role_lambda_secretsmanager_rds_mysql_password_rotation"></a> [iam\_role\_lambda\_secretsmanager\_rds\_mysql\_password\_rotation](#output\_iam\_role\_lambda\_secretsmanager\_rds\_mysql\_password\_rotation) | n/a |
| <a name="output_lambda_secretsmanager_rds_mysql_password_rotation"></a> [lambda\_secretsmanager\_rds\_mysql\_password\_rotation](#output\_lambda\_secretsmanager\_rds\_mysql\_password\_rotation) | n/a |
<!-- END_TF_DOCS -->