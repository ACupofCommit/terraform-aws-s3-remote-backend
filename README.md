# terraform-s3-remote-backend
Terraform module for terraform s3 remote backend usage.

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
| name\_prefix | String to use as prefix on resource name | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| dynamodb\_table\_name | Dynamodb table to lock terraform backend state |
| kms\_key\_arn | KMS key for server side encrypt of terraform state in S3 |
| s3\_bucket\_name | S3 bucket save terraform state |