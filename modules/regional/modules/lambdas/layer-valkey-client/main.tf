resource "aws_s3_object" "layer_zip" {
  count  = var.create ? 1 : 0
  bucket = var.bucket_name
  key    = "lambda-layers/layer-valkey-client.zip"
  source = "${path.module}/files/layer-valkey-client.zip"
  etag   = filemd5("${path.module}/files/layer-valkey-client.zip")
}

module "layer_valkey_client" {
  count          = var.create ? 1 : 0
  source         = "terraform-aws-modules/lambda/aws"
  version        = "~> 8.0"
  create_layer   = true
  create_package = false
  layer_name     = "layer-valkey-client"
  description    = "Lambda Layer for ValKey"
  s3_existing_package = var.bucket_name != "" ? {
    bucket = var.bucket_name
    key    = "lambda-layers/layer-valkey-client.zip"
  } : null
  layer_skip_destroy = true
  depends_on         = [aws_s3_object.layer_zip]
}