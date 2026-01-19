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

# EC2 Module - Compute instances
module "ec2" {
  source = "./modules/ec2"

  instance_type     = var.ec2_instance_type
  key_name          = var.ec2_key_name
  environment       = var.environment
  iam_instance_profile = module.iam.ec2_instance_profile_name
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
