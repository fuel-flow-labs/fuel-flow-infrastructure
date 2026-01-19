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
output "ec2_role_arn" {
  description = "IAM role ARN for EC2 instances"
  value       = module.iam.ec2_role_arn
}

output "ec2_instance_profile_name" {
  description = "IAM instance profile name for EC2"
  value       = module.iam.ec2_instance_profile_name
}

# EC2 Outputs
output "ec2_instance_ids" {
  description = "EC2 instance IDs"
  value       = module.ec2.instance_ids
}

output "ec2_public_ips" {
  description = "EC2 instance public IP addresses"
  value       = module.ec2.public_ips
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
