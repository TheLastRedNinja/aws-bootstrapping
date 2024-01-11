locals {
  region = "eu-west-1"
  default_tags = {
    owner = "Denis Murphy"
  }
}

###################################################
## Config for state bucket
###################################################
resource "aws_s3_bucket" "terraform-state-storage-bucket" {
  bucket              = "denis-murphy-terraform-state-store"
  object_lock_enabled = true

  tags = merge(local.default_tags, {})
}

resource "aws_s3_bucket_versioning" "versioning_state_store" {
  bucket = aws_s3_bucket.terraform-state-storage-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


data "aws_iam_policy_document" "access-terraform-state-bucket" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::denis-murphy-terraform-state-store"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::denis-murphy-terraform-state-store/terraform/aws-deep-dive/vpc"]
  }
}

###################################################
## Config for locking table
###################################################

data "aws_iam_policy_document" "access-terraform-state-lock-table" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:*:*:table/denis-murphy-terraform-state-lock-table"]
  }
}

resource "aws_dynamodb_table" "terraform-state-lock-table" {
  name           = "denis-murphy-terraform-state-lock-table"
  hash_key       = "LockID"
  read_capacity  = 1
  write_capacity = 1

  ttl {
    enabled        = false
    attribute_name = ""
  }

  point_in_time_recovery {
    enabled = false
  }

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(local.default_tags, {})
}

import {
  to = aws_dynamodb_table.terraform-state-lock-table
  id = "denis-murphy-terraform-state-lock-table"
}

import {
  to = aws_s3_bucket.terraform-state-storage-bucket
  id = "denis-murphy-terraform-state-store"
}

import {
  to = aws_s3_bucket_versioning.versioning_state_store
  id = "denis-murphy-terraform-state-store"
}