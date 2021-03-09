# terraform-aws-s3-remote-backend
Terraform codes for terraform s3 remote backend.

## Usages
Refer the example/

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.13.5 |
| aws | ~> 3.0 |
| random | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3.0 |
| random | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket\_name | S3 Bucket name for terraform state | `string` | `null` | no |
| name\_prefix | String to use as prefix on resource name | `string` | n/a | yes |
| name\_suffix | String to use as suffix on resource name | `string` | `null` | no |
| tags | Common tags of resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| dynamodb\_table\_name | Dynamodb table to lock terraform backend state |
| kms\_key\_arn | KMS key for server side encrypt of terraform state in S3 |
| region | The AWS region where the resources are provisioned |
| s3\_bucket\_name | S3 bucket save terraform state |

