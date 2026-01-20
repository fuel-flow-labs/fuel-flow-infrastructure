# Fuel Flow Infrastructure

Infrastructure as Code (IaC) repository for managing AWS deployments using both Terraform and CloudFormation.

## Overview

This repository contains modular and reusable infrastructure code for deploying and managing AWS resources for the Fuel Flow application. It supports multiple environments (dev, staging, prod) and provides two IaC approaches:

- **Terraform**: Primary IaC tool with modular structure
- **CloudFormation**: Alternative IaC approach using AWS native templates

## Architecture

The infrastructure includes the following AWS resources:

- **S3 Buckets**: Application data, logs, and backups storage
- **Lambda Functions**: Serverless compute for microservices
- **API Gateway**: REST API endpoints for Lambda functions
- **RDS PostgreSQL**: Managed relational database
- **IAM Roles**: Security policies for Lambda, RDS, and other services
- **Security Groups**: Network security configurations
- **Terraform State Backend**: S3 + DynamoDB for remote state management

## Directory Structure

```
.
├── terraform/
│   ├── main.tf                 # Main Terraform configuration
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── backend.tf              # Backend configuration for state
│   └── modules/
│       ├── terraform-state/    # S3 + DynamoDB for state backend
│       ├── s3/                 # S3 bucket configurations
│       ├── lambda/             # Lambda function configurations
│       ├── api-gateway/        # API Gateway REST API
│       ├── rds/                # RDS database configurations
│       └── iam/                # IAM roles and policies
├── cloudformation/
│   ├── s3-buckets.yaml         # S3 CloudFormation template
│   ├── ec2-instances.yaml      # EC2 CloudFormation template (legacy)
│   ├── rds-database.yaml       # RDS CloudFormation template
│   └── iam-roles.yaml          # IAM CloudFormation template
└── README.md
```

## Prerequisites

### For Terraform

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with appropriate permissions

### For CloudFormation

- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with appropriate permissions

### AWS Credentials Setup

Configure AWS credentials using one of these methods:

```bash
# Option 1: AWS CLI configure
aws configure

# Option 2: Environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Option 3: AWS credentials file (~/.aws/credentials)
[default]
aws_access_key_id = your-access-key
aws_secret_access_key = your-secret-key
region = us-east-1
```

## Terraform Setup and Usage

### 1. Initial Setup - Create State Backend

First, create the S3 bucket and DynamoDB table for storing Terraform state:

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the state backend resources
terraform plan -target=module.terraform_state

# Create the state backend (S3 + DynamoDB)
terraform apply -target=module.terraform_state
```

### 2. Configure Remote Backend

After creating the state backend infrastructure:

1. Edit `backend.tf` and uncomment the backend configuration block
2. Update the bucket name and region if needed
3. Migrate state to remote backend:

```bash
terraform init -migrate-state
```

### 3. Deploy Infrastructure

Deploy all infrastructure resources:

```bash
# Review all changes
terraform plan

# Apply changes
terraform apply

# For specific environment
terraform apply -var="environment=prod"
```

### 4. Customize Variables

Create a `terraform.tfvars` file to customize variables:

```hcl
aws_region              = "us-west-2"
environment             = "prod"
rds_instance_class      = "db.t3.small"
rds_allocated_storage   = 50
```

### 5. View Outputs

```bash
terraform output
```

### 6. Destroy Infrastructure

```bash
# Destroy all resources
terraform destroy

# Destroy specific module
terraform destroy -target=module.lambda
```

## CloudFormation Setup and Usage

### 1. Deploy IAM Roles

```bash
aws cloudformation create-stack \
  --stack-name fuel-flow-iam-dev \
  --template-body file://cloudformation/iam-roles.yaml \
  --parameters ParameterKey=Environment,ParameterValue=dev \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### 2. Deploy S3 Buckets

```bash
aws cloudformation create-stack \
  --stack-name fuel-flow-s3-dev \
  --template-body file://cloudformation/s3-buckets.yaml \
  --parameters ParameterKey=Environment,ParameterValue=dev \
  --region us-east-1
```

### 3. Deploy EC2 Instances (Legacy - Use Lambda for serverless)

**Note**: The Terraform configuration now uses Lambda + API Gateway for serverless microservices. The EC2 CloudFormation template is kept for reference but not recommended for new deployments.

```bash
aws cloudformation create-stack \
  --stack-name fuel-flow-ec2-dev \
  --template-body file://cloudformation/ec2-instances.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=InstanceType,ParameterValue=t3.micro \
    ParameterKey=KeyName,ParameterValue=my-key-pair \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### 4. Deploy RDS Database

```bash
aws cloudformation create-stack \
  --stack-name fuel-flow-rds-dev \
  --template-body file://cloudformation/rds-database.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=DBName,ParameterValue=fuelflowdb \
    ParameterKey=DBUsername,ParameterValue=admin \
    ParameterKey=DBInstanceClass,ParameterValue=db.t3.micro \
  --region us-east-1
```

### 5. Monitor Stack Creation

```bash
# Check stack status
aws cloudformation describe-stacks \
  --stack-name fuel-flow-ec2-dev \
  --query 'Stacks[0].StackStatus'

# Watch stack events
aws cloudformation describe-stack-events \
  --stack-name fuel-flow-ec2-dev \
  --max-items 10
```

### 6. Update Stacks

```bash
aws cloudformation update-stack \
  --stack-name fuel-flow-ec2-dev \
  --template-body file://cloudformation/ec2-instances.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=InstanceType,ParameterValue=t3.small \
  --capabilities CAPABILITY_NAMED_IAM
```

### 7. Delete Stacks

```bash
# Delete in reverse order of dependencies
aws cloudformation delete-stack --stack-name fuel-flow-rds-dev
aws cloudformation delete-stack --stack-name fuel-flow-ec2-dev
aws cloudformation delete-stack --stack-name fuel-flow-s3-dev
aws cloudformation delete-stack --stack-name fuel-flow-iam-dev
```

## Module Documentation

### Terraform State Module

Creates S3 bucket and DynamoDB table for Terraform state management with:
- Server-side encryption (AES256)
- Versioning enabled
- Public access blocked
- State locking via DynamoDB

### S3 Module

Creates three S3 buckets:
- **app-data**: Application data storage with versioning
- **logs**: Application logs storage
- **backups**: Backup storage with versioning

All buckets have:
- Server-side encryption enabled
- Public access blocked
- Environment-based naming

### Lambda Module

Creates Lambda functions with:
- Node.js 20.x runtime
- VPC access for RDS connectivity
- Environment variables for database configuration
- CloudWatch Logs integration
- IAM role with S3 and VPC permissions

### API Gateway Module

Creates REST API with:
- Regional endpoint
- Lambda proxy integration
- `/api` base path with wildcard routes
- CloudWatch access logging
- Stage-based deployment (dev, staging, prod)

### RDS Module

Creates PostgreSQL RDS instance with:
- PostgreSQL 16.1 engine
- Encrypted storage (GP3)
- Automated backups (7-day retention)
- CloudWatch logs export
- Password stored in AWS Secrets Manager
- Multi-AZ support (configurable)

### IAM Module

Creates IAM roles for:
- **Lambda**: S3 access, VPC access, and CloudWatch logs
- **RDS**: Enhanced monitoring

## Security Best Practices

1. **Never commit sensitive data**: Use `.gitignore` to exclude `.tfvars`, `.tfstate`, and credential files
2. **Use AWS Secrets Manager**: Database passwords are stored securely
3. **Enable encryption**: All S3 buckets and RDS instances use encryption
4. **Least privilege**: IAM roles have minimal required permissions
5. **State locking**: DynamoDB prevents concurrent state modifications
6. **Remote state**: Terraform state is stored in encrypted S3 bucket

## Environment Management

The infrastructure supports multiple environments through variables:

```bash
# Development
terraform apply -var="environment=dev"

# Staging
terraform apply -var="environment=staging"

# Production
terraform apply -var="environment=prod"
```

Each environment creates isolated resources with environment-specific naming.

## Troubleshooting

### Terraform Issues

**State lock error:**
```bash
# Force unlock if necessary (use with caution)
terraform force-unlock <LOCK_ID>
```

**Module not found:**
```bash
terraform init -upgrade
```

### CloudFormation Issues

**Stack stuck in CREATE_FAILED:**
```bash
# Get failure reason
aws cloudformation describe-stack-events \
  --stack-name <stack-name> \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'
```

**Delete stuck stack:**
```bash
# Skip resources that can't be deleted
aws cloudformation delete-stack \
  --stack-name <stack-name> \
  --retain-resources <resource-logical-id>
```

## Cost Optimization

- Use `t3.micro` instances for development
- Enable RDS auto-scaling for production
- Use S3 lifecycle policies for log rotation
- Monitor costs with AWS Cost Explorer
- Tag all resources for cost allocation

## Contributing

1. Create a feature branch
2. Make changes to infrastructure code
3. Test in dev environment
4. Submit pull request
5. Apply to production after approval

## License

This infrastructure code is maintained by Fuel Flow Labs.

## Support

For issues or questions:
- Create an issue in this repository
- Contact the DevOps team

## Useful Commands Reference

### Terraform

```bash
terraform init          # Initialize Terraform
terraform fmt           # Format code
terraform validate      # Validate syntax
terraform plan          # Preview changes
terraform apply         # Apply changes
terraform destroy       # Destroy infrastructure
terraform output        # Show outputs
terraform state list    # List resources in state
```

### CloudFormation

```bash
# List stacks
aws cloudformation list-stacks

# Describe stack
aws cloudformation describe-stacks --stack-name <name>

# Get stack outputs
aws cloudformation describe-stacks \
  --stack-name <name> \
  --query 'Stacks[0].Outputs'

# Validate template
aws cloudformation validate-template \
  --template-body file://template.yaml
```

## Future Enhancements

Consider these improvements for production deployments:

- Migrate from Amazon Linux 2 to Amazon Linux 2023 (AL2 EOL: June 2025) if using EC2
- Make RDS PostgreSQL version configurable via variables
- Implement variable-based API Gateway authorization (API keys, Cognito, etc.)
- Add expanded special characters for RDS passwords
- Align password policies between Terraform and CloudFormation
- Implement Multi-AZ deployments for RDS
- Add Lambda function layers for shared dependencies
- Configure Auto Scaling for Lambda concurrency
- Set up CloudFront for API Gateway caching
- Implement AWS WAF for additional security
- Add VPC configuration for Lambda functions
- Configure custom domain names for API Gateway
