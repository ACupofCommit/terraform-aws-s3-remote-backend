data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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

locals {
  bucket_name = var.bucket_name == null ? "${var.name_prefix}-tfstate-${random_id.suffix.hex}" : var.bucket_name
  name_suffix = var.name_suffix == null ? random_id.suffix.hex : var.name_suffix
}

# Generates for each function a unique function name
resource "random_id" "suffix" {
  byte_length = 6
}

resource "aws_s3_bucket" "tfstate_backend_log" {
  count = var.log_bucket_name == null ? 1 : 0
  bucket = "${var.name_prefix}-tfstate-log-${local.name_suffix}"
  acl = "log-delivery-write"
  force_destroy = false
  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "tfstate_backend_log" {
  count = var.log_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.tfstate_backend_log[0].id
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}

resource "aws_s3_bucket" "tfstate_backend" {
  bucket = local.bucket_name
  acl = "private"
  force_destroy = false
  versioning {
    enabled = true
  }
  logging {
    target_bucket = var.log_bucket_name == null ? aws_s3_bucket.tfstate_backend_log[0].id : var.log_bucket_name
    target_prefix = var.log_prefix == null ? local.bucket_name : var.log_prefix
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.tfstate_backend.arn
        sse_algorithm = "aws:kms"
      }
    }
  }
  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "tfstate_backend" {
  bucket = aws_s3_bucket.tfstate_backend.id
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}

resource "aws_kms_key" "tfstate_backend" {
  description = "${var.name_prefix} key. Terraform s3 remote state bucket encrypt"
  enable_key_rotation = true
  tags = var.tags
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
  name = "${var.name_prefix}-tfstate-lock-${local.name_suffix}"
  hash_key = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = var.tags
}