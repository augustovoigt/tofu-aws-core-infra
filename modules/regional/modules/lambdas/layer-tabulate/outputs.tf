############################################################
# AWS Lambda Layer - Tabulate - Outputs                   🇧🇷
############################################################

output "layer_tabulate" {
  value = var.create ? module.layer_tabulate[0] : null
}