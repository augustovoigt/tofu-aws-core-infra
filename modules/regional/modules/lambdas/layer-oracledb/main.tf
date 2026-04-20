############################################################
# AWS Lambda Layer - Python OracleDB                      🇧🇷
############################################################

locals {
  oracledb_zip_hash = filebase64sha256("${path.module}/files/layer-oracledb.zip")
}

resource "aws_s3_object" "layer_zip" {
  count       = var.create ? 1 : 0
  bucket      = var.bucket_name
  key         = "lambda-layers/layer-oracledb.zip"
  source      = "${path.module}/files/layer-oracledb.zip"
  source_hash = local.oracledb_zip_hash
}

module "layer_oracledb" {
  count                    = var.create ? 1 : 0
  source                   = "terraform-aws-modules/lambda/aws"
  version                  = "~> 8.0"
  create_layer             = true
  create_package           = false
  ignore_source_code_hash  = true
  layer_name               = "layer-oracledb"
  description              = "Lambda Layer for the new Python oracledb integration"
  compatible_architectures = ["x86_64"]
  s3_existing_package = var.bucket_name != "" ? {
    bucket = var.bucket_name
    key    = "lambda-layers/layer-oracledb.zip"
  } : null
  layer_skip_destroy = true
  depends_on         = [aws_s3_object.layer_zip]
}