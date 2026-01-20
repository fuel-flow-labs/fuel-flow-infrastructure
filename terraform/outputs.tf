# Outputs from Terraform modules

# Terraform State Backend Outputs
output "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  value       = module.terraform_state.state_bucket_name
}

output "terraform_state_lock_table" {
  description = "DynamoDB table for Terraform state locking"
  value       = module.terraform_state.dynamodb_table_name
}

# S3 Outputs
output "application_buckets" {
  description = "Application S3 bucket names"
  value       = module.s3.bucket_names
}

# IAM Outputs
output "lambda_role_arn" {
  description = "IAM role ARN for Lambda functions"
  value       = module.iam.lambda_role_arn
}

# Lambda Outputs
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

# API Gateway Outputs
output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "api_id" {
  description = "API Gateway REST API ID"
  value       = module.api_gateway.api_id
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.db_name
}
