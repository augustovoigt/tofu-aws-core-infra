############################################################
# AWS Lambda Layer - Python Cryptography                  🇧🇷
############################################################

locals {
  cryptography_zip_hash = filebase64sha256("${path.module}/files/layer-cryptography.zip")
}

resource "aws_s3_object" "layer_zip" {
  count       = var.create ? 1 : 0
  bucket      = var.bucket_name
  key         = "lambda-layers/layer-cryptography.zip"
  source      = "${path.module}/files/layer-cryptography.zip"
  source_hash = local.cryptography_zip_hash
}

module "layer_cryptography" {
  count                    = var.create ? 1 : 0
  source                   = "terraform-aws-modules/lambda/aws"
  version                  = "~> 8.0"
  create_layer             = true
  create_package           = false
  ignore_source_code_hash  = true
  layer_name               = "layer-cryptography"
  description              = "Lambda Layer for the Python MySQL Cryptography - Python 3.13"
  compatible_architectures = ["x86_64"]
  s3_existing_package = var.bucket_name != "" ? {
    bucket = var.bucket_name
    key    = "lambda-layers/layer-cryptography.zip"
  } : null
  layer_skip_destroy = true
  depends_on         = [aws_s3_object.layer_zip]
}