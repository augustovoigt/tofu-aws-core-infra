############################################################
# AWS Lambda Layer - Tabulate                             🇧🇷
############################################################

resource "aws_s3_object" "layer_zip" {
  count  = var.create ? 1 : 0
  bucket = var.bucket_name
  key    = "lambda-layers/layer-tabulate.zip"
  source = "${path.module}/files/layer-tabulate.zip"
  etag   = filemd5("${path.module}/files/layer-tabulate.zip")
}

module "layer_tabulate" {
  count          = var.create ? 1 : 0
  source         = "terraform-aws-modules/lambda/aws"
  version        = "~> 8.0"
  create_layer   = true
  create_package = false
  layer_name     = "layer-tabulate"
  description    = "Lambda Layer for Tabulate"
  s3_existing_package = var.bucket_name != "" ? {
    bucket = var.bucket_name
    key    = "lambda-layers/layer-tabulate.zip"
  } : null
  layer_skip_destroy = true
  depends_on         = [aws_s3_object.layer_zip]
}