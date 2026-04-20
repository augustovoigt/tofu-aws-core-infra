############################################################
# AWS Lambda Layer - Python OracleDB - Outputs            🇧🇷
############################################################

output "layer_oracledb" {
  value = var.create ? module.layer_oracledb[0] : null
}