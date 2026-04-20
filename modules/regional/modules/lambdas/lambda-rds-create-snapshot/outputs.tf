############################################################
# Lambda RDS Create Snapshot - Outputs                    🇧🇷
############################################################

output "lambda_rds_create_snapshot" {
  value = module.lambda_rds_create_snapshot
}

output "iam_role_lambda_rds_create_snapshot" {
  value = module.iam_role_lambda_rds_create_snapshot
}