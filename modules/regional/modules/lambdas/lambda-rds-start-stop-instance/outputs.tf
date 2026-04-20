############################################################
# Lambda RDS Start Stop Instance - Outputs                🇧🇷
############################################################

output "lambda_rds_start_stop_instance" {
  value = module.lambda_rds_start_stop_instance
}

output "iam_role_lambda_rds_start_stop_instance" {
  value = module.iam_role_lambda_rds_start_stop_instance
}