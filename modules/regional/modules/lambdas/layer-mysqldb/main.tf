############################################################
# AWS Lambda Layer - Python MySQLDB                      🇧🇷
############################################################

locals {
  mysqldb_zip_hash = filebase64sha256("${path.module}/files/layer-mysqldb.zip")
}

resource "aws_s3_object" "layer_zip" {
  count       = var.create ? 1 : 0
  bucket      = var.bucket_name
  key         = "lambda-layers/layer-mysqldb.zip"
  source      = "${path.module}/files/layer-mysqldb.zip"
  source_hash = local.mysqldb_zip_hash
}

module "layer_mysqldb" {
  count                    = var.create ? 1 : 0
  source                   = "terraform-aws-modules/lambda/aws"
  version                  = "~> 8.0"
  create_layer             = true
  create_package           = false
  ignore_source_code_hash  = true
  layer_name               = "layer-mysqldb"
  description              = "Lambda Layer for the new Python mysqldb integration - Python 3.12"
  compatible_architectures = ["x86_64"]
  s3_existing_package = var.bucket_name != "" ? {
    bucket = var.bucket_name
    key    = "lambda-layers/layer-mysqldb.zip"
  } : null
  layer_skip_destroy = true
  depends_on         = [aws_s3_object.layer_zip]
}