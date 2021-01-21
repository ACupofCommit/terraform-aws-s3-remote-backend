data "aws_caller_identity" "current" {}

terraform {
  required_version = ">= 0.13.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Generates for each function a unique function name
resource "random_id" "suffix" {
  byte_length = 6
}

resource "aws_s3_bucket" "tfstate_backend_log" {
  bucket = "${var.name_prefix}-tfstate-log-${random_id.suffix.hex}"
  acl = "log-delivery-write"
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "tfstate_backend_log" {
  bucket = aws_s3_bucket.tfstate_backend_log.id
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}

locals {
  bucket_name = "${var.name_prefix}-tfstate-${random_id.suffix.hex}"
}

resource "aws_s3_bucket" "tfstate_backend" {
  bucket = local.bucket_name
  acl = "private"
  force_destroy = false
  logging {
    target_bucket = aws_s3_bucket.tfstate_backend_log.id
    target_prefix = local.bucket_name
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.tfstate_backend.arn
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_backend" {
  bucket = aws_s3_bucket.tfstate_backend.id
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}

resource "aws_kms_key" "tfstate_backend" {
  description = "key for terraform s3 remote state bucket encrypt"
  enable_key_rotation = true
}

data "aws_iam_policy_document" "encrypted_transit_bucket_policy" {
  statement {
    sid = "DenyUnsecuredTransport"
    actions = ["s3:*"]
    condition {
      test = "Bool"
      values = [ "false" ]
      variable = "aws:SecureTransport"
    }
    effect = "Deny"
    principals {
      type = "AWS"
      identifiers = [ "*" ]
    }
    resources = [
      aws_s3_bucket.tfstate_backend.arn,
      "${aws_s3_bucket.tfstate_backend.arn}/*"
    ]
  }
  statement {
    sid = "OnlyAllowCorrectHeader"
    actions = [ "s3:PutObject" ]
    condition {
      test = "StringEquals"
      values = [ "aws:kms" ]
      variable = "s3:x-amz-server-side-encryption"
    }
    condition {
      test = "StringEquals"
      values = [ "bucket-owner-full-control" ]
      variable = "s3:x-amz-acl"
    }
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [ "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" ]
    }
    resources = [
      aws_s3_bucket.tfstate_backend.arn,
      "${aws_s3_bucket.tfstate_backend.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "tfstate_backend" {
  bucket = aws_s3_bucket.tfstate_backend.id
  policy = data.aws_iam_policy_document.encrypted_transit_bucket_policy.json
}

resource "aws_dynamodb_table" "remote_state_backend" {
  name = "${var.name_prefix}-tfstate-lock"
  hash_key = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
}