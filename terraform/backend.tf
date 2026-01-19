# Backend configuration for storing Terraform state in S3 with DynamoDB locking
# Uncomment and configure after creating the S3 bucket and DynamoDB table

# terraform {
#   backend "s3" {
#     bucket         = "fuel-flow-terraform-state"
#     key            = "terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "fuel-flow-terraform-locks"
#     encrypt        = true
#   }
# }

# To create the backend infrastructure, first apply with local backend:
# 1. Comment out the backend block above
# 2. Run: terraform init
# 3. Run: terraform apply -target=module.terraform_state
# 4. Uncomment the backend block
# 5. Run: terraform init -migrate-state
