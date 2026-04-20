# Subnet Groups

resource "aws_db_subnet_group" "db_private_subnet_group" {
  name       = "${var.resource_prefix}-private-db-subnet-group"
  subnet_ids = var.private_subnet_id
}

resource "aws_db_subnet_group" "db_public_subnet_group" {
  name       = "${var.resource_prefix}-public-db-subnet-group"
  subnet_ids = var.public_subnet_id
}

# Security Groups

resource "aws_security_group" "aws_service_base" {
  name        = "${var.resource_prefix}-aws-service-base"
  description = "Base security group which can be applied to instances and referenced as a source in other security group ingress rules."
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${var.resource_prefix}-aws-service-base"
  }, var.base_security_group_tags)

  lifecycle {
    ignore_changes = [
      description
    ]
  }
}

resource "aws_security_group" "aws_database" {
  name        = "${var.resource_prefix}-aws-database"
  description = "Allow connections to RDS managed databases from aws-service-base security group."
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.aws_service_base.id]
    description     = "Allow PostgreSQL connections from instances in the aws-service-base security group."
  }

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.aws_service_base.id]
    description     = "Allow MySQL connections from instances in the aws-service-base security group."
  }

  ingress {
    from_port       = 1521
    to_port         = 1521
    protocol        = "tcp"
    security_groups = [aws_security_group.aws_service_base.id]
    description     = "Allow Oracle connections from instances in the aws-service-base security group."
  }

  ingress {
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    security_groups = [aws_security_group.aws_service_base.id]
    description     = "Allow MSSQL connections from instances in the aws-service-base security group."
  }

  tags = {
    Name = "${var.resource_prefix}-aws-database"
  }

  lifecycle {
    ignore_changes = [
      description
    ]
  }
}