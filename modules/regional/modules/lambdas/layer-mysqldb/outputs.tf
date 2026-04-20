############################################################
# AWS Lambda Layer - MySQLDB - Outputs                  🇧🇷
############################################################

output "layer_mysqldb" {
  value = var.create ? module.layer_mysqldb[0] : null
}
