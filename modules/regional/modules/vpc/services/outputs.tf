output "aws_service_base_security_group" {
  value = aws_security_group.aws_service_base
}

output "aws_database_security_group" {
  value = aws_security_group.aws_database
}

output "db_private_subnet_group" {
  value = aws_db_subnet_group.db_private_subnet_group
}

output "db_public_subnet_group" {
  value = aws_db_subnet_group.db_public_subnet_group
}