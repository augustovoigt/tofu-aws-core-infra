############################################################
# Lambda RDS Delete Instance - Outputs                    🇧🇷
############################################################

output "lambda_rds_delete_instance" {
  value = module.lambda_rds_delete_instance
}

output "iam_role_lambda_rds_delete_instance" {
  value = module.iam_role_lambda_rds_delete_instance
}