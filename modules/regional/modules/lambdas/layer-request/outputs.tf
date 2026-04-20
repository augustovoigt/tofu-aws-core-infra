############################################################
# AWS Lambda Layer - Request - Outputs                    🇧🇷
############################################################

output "layer_request" {
  value = var.create ? module.layer_request[0] : null
}