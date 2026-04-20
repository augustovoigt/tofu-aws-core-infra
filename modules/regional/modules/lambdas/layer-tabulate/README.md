## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_layer_tabulate"></a> [layer\_tabulate](#module\_layer\_tabulate) | terraform-aws-modules/lambda/aws | ~> 7.0 |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_layer_tabulate"></a> [layer\_tabulate](#output\_layer\_tabulate) | n/a |

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_layer_tabulate"></a> [layer\_tabulate](#module\_layer\_tabulate) | terraform-aws-modules/lambda/aws | ~> 8.0 |

## Resources

| Name | Type |
|------|------|
| [aws_s3_object.layer_zip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Bucket name for the layer | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_layer_tabulate"></a> [layer\_tabulate](#output\_layer\_tabulate) | n/a |
<!-- END_TF_DOCS -->