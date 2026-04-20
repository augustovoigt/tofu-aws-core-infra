# AWS S3

locals {
  default_s3_buckets = {
    platform_temp = {
      create_bucket            = true
      bucket                   = "platform-temp-${var.aws_account_id}-${var.aws_region}"
      control_object_ownership = true
      object_ownership         = "BucketOwnerEnforced"
      attach_policy            = true
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Deny",
            "Principal" : "*",
            "Action" : "s3:*",
            "Resource" : "arn:aws:s3:::platform-temp-${var.aws_account_id}-${var.aws_region}/*",
            "Condition" : {
              "StringNotEqualsIfExists" : {
                "s3:x-amz-server-side-encryption" : "AES256"
              },
              "Null" : {
                "s3:x-amz-server-side-encryption" : "false"
              }
            }
          },
          {
            "Sid" : "DenyInsecureRequests",
            "Effect" : "Deny",
            "Principal" : "*",
            "Action" : "s3:*",
            "Resource" : [
              "arn:aws:s3:::platform-temp-${var.aws_account_id}-${var.aws_region}/*",
              "arn:aws:s3:::platform-temp-${var.aws_account_id}-${var.aws_region}"
            ],
            "Condition" : {
              "Bool" : {
                "aws:SecureTransport" : "false"
              }
            }
          }
        ]
      })
      versioning = {
        enabled = true
      }
      tags = {
        Name = "platform-temp-${var.aws_account_id}-${var.aws_region}"
      }
    }
  }

  s3_buckets = merge(local.default_s3_buckets, var.s3_buckets)
}

module "s3_bucket" {
  for_each = var.create_s3 ? local.s3_buckets : {}

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.10.0"

  bucket                   = each.value.bucket
  control_object_ownership = try(each.value.control_object_ownership, true)
  create_bucket            = try(each.value.create_bucket, true)
  object_ownership         = try(each.value.object_ownership, "BucketOwnerEnforced")
  attach_policy            = try(each.value.attach_policy, false)
  policy                   = try(each.value.policy, null)
  versioning               = try(each.value.versioning, null)
  tags                     = try(each.value.tags, null)
}

# AWS S3 - Bucket Object

resource "aws_s3_object" "lambda_layers" {
  count      = var.create_s3 ? 1 : 0
  bucket     = try(module.s3_bucket["platform_temp"].s3_bucket_id, null)
  key        = "lambda-layers/"
  content    = ""
  depends_on = [module.s3_bucket]
}