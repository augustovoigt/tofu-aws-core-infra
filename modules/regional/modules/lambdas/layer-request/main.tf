############################################################
# AWS Lambda Layer - Request                              🇧🇷
############################################################

resource "aws_s3_object" "layer_zip" {
  count  = var.create ? 1 : 0
  bucket = var.bucket_name
  key    = "lambda-layers/layer-request.zip"
  source = "${path.module}/files/layer-request.zip"
  etag   = filemd5("${path.module}/files/layer-request.zip")
}

module "layer_request" {
  count          = var.create ? 1 : 0
  source         = "terraform-aws-modules/lambda/aws"
  version        = "~> 8.0"
  create_layer   = true
  create_package = false
  layer_name     = "layer-request"
  description    = "Lambda Layer for Request"
  s3_existing_package = var.bucket_name != "" ? {
    bucket = var.bucket_name
    key    = "lambda-layers/layer-request.zip"
  } : null
  layer_skip_destroy = true
  depends_on         = [aws_s3_object.layer_zip]
}