####################################################################
# Lambda Secretsmanager RDS MySQL Password Rotation - Outputs     🇧🇷
####################################################################

output "lambda_secretsmanager_rds_mysql_password_rotation" {
  value = module.lambda_secretsmanager_rds_mysql_password_rotation
}

output "iam_role_lambda_secretsmanager_rds_mysql_password_rotation" {
  value = module.iam_role_lambda_secretsmanager_rds_mysql_password_rotation
}