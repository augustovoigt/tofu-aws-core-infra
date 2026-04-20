############################################################
# AWS Lambda Layer - Cryptography - Outputs               🇧🇷
############################################################

output "layer_cryptography" {
  value = var.create ? module.layer_cryptography[0] : null
}
