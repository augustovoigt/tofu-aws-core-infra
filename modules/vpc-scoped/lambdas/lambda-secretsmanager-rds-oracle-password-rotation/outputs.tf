######################################################################
# Lambda Secretsmanager RDS Oracle Password Rotation - Outputs      🇧🇷
######################################################################

output "lambda_secretsmanager_rds_oracle_password_rotation" {
  value = module.lambda_secretsmanager_rds_oracle_password_rotation
}

output "iam_role_lambda_secretsmanager_rds_oracle_password_rotation" {
  value = module.iam_role_lambda_secretsmanager_rds_oracle_password_rotation
}