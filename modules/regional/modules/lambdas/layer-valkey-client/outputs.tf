# AWS Lambda Layer - Valkey - Outputs

output "layer_valkey_client" {
  value = var.create ? module.layer_valkey_client[0] : null
}
