############################################################
# Lambda RDS Delete Snapshot - Outputs                    🇧🇷
############################################################

output "lambda_rds_delete_snapshot" {
  value = module.lambda_rds_delete_snapshot
}

output "iam_role_lambda_rds_delete_snapshot" {
  value = module.iam_role_lambda_rds_delete_snapshot
}