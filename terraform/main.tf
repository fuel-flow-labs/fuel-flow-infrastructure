# Main Terraform configuration file
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "fuel-flow"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Terraform State Backend Infrastructure (S3 + DynamoDB)
module "terraform_state" {
  source = "./modules/terraform-state"

  bucket_name        = var.state_bucket_name
  dynamodb_table_name = var.state_lock_table_name
  environment        = var.environment
}

# S3 Module - Application storage buckets
module "s3" {
  source = "./modules/s3"

  bucket_prefix = var.s3_bucket_prefix
  environment   = var.environment
}

# IAM Module - Roles and policies
module "iam" {
  source = "./modules/iam"

  environment = var.environment
}

# API Gateway Module - REST API
module "api_gateway" {
  source = "./modules/api-gateway"

  environment        = var.environment
  lambda_invoke_arn  = module.lambda.invoke_arn
}

# Lambda Module - Serverless functions
module "lambda" {
  source = "./modules/lambda"

  environment                = var.environment
  lambda_role_arn           = module.iam.lambda_role_arn
  api_gateway_execution_arn = module.api_gateway.api_execution_arn
  db_endpoint               = module.rds.db_endpoint
  db_name                   = module.rds.db_name
}

# RDS Module - Database instances
module "rds" {
  source = "./modules/rds"

  db_name             = var.rds_db_name
  db_username         = var.rds_username
  db_instance_class   = var.rds_instance_class
  allocated_storage   = var.rds_allocated_storage
  environment         = var.environment
}
