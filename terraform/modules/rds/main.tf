# RDS Module
# Creates RDS database instances

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "fuel-flow-rds-sg-${var.environment}"
  description = "Security group for Fuel Flow RDS instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "fuel-flow-rds-sg-${var.environment}"
    Environment = var.environment
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "fuel-flow-rds-subnet-group-${var.environment}"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name        = "fuel-flow-rds-subnet-group-${var.environment}"
    Environment = var.environment
  }
}

# Random password for RDS
resource "random_password" "db_password" {
  length  = 16
  special = true
  # Use conservative set of special characters safe for connection strings
  override_special = "!@#$%^&*"
}

# Store password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name        = "fuel-flow-rds-password-${var.environment}"
  description = "RDS database password for ${var.environment}"

  tags = {
    Name        = "fuel-flow-rds-password-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier     = "fuel-flow-db-${var.environment}"
  engine         = "postgres"
  engine_version = "16.1"

  instance_class    = var.db_instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "fuel-flow-db-${var.environment}-final-snapshot" : null

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name        = "fuel-flow-db-${var.environment}"
    Environment = var.environment
  }
}
