############################################################
# Lambda RDS Oracle Update Users Credentials - Outputs    🇧🇷
############################################################

output "lambda_rds_oracle_update_users_credentials" {
  value = module.lambda_rds_oracle_update_users_credentials
}

output "iam_role_lambda_rds_oracle_update_users_credentials" {
  value = module.iam_role_lambda_rds_oracle_update_users_credentials
}