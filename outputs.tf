output "s3_bucket_name" {
  description = "S3 bucket save terraform state"
  value = aws_s3_bucket.tfstate_backend.id
}
output "dynamodb_table_name" {
  description = "Dynamodb table to lock terraform backend state"
  value = aws_dynamodb_table.remote_state_backend.id
}
output "kms_key_arn" {
  description = "KMS key for server side encrypt of terraform state in S3"
  value = aws_kms_key.tfstate_backend.arn
}
output "region" {
  description = "The AWS region where the resources are provisioned"
  value = data.aws_region.current.name
}
