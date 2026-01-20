# Quick Start Guide

This guide will help you deploy the Fuel Flow infrastructure quickly.

## Prerequisites Checklist

- [ ] AWS Account with admin access
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.0 installed (for Terraform deployment)
- [ ] Git installed

## Option 1: Terraform Deployment (Recommended)

### Step 1: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, and default region (e.g., us-east-1)
```

### Step 2: Prepare Terraform Configuration

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferred values
```

### Step 3: Deploy State Backend First

```bash
terraform init
terraform apply -target=module.terraform_state
```

### Step 4: Enable Remote State (Optional but Recommended)

Edit `backend.tf` and uncomment the backend block, then:

```bash
terraform init -migrate-state
```

### Step 5: Deploy All Infrastructure

```bash
terraform plan    # Review changes
terraform apply   # Deploy (will prompt for confirmation)
```

### Step 6: Get Outputs

```bash
terraform output
```

You'll see outputs including:
- S3 bucket names
- EC2 instance IDs and IPs
- RDS endpoint (sensitive, use: `terraform output -json`)

### Step 7: Access Your Infrastructure

- **EC2 Web Server**: Access the public IP shown in outputs via HTTP
- **RDS Password**: Retrieve from AWS Secrets Manager
  ```bash
  aws secretsmanager get-secret-value \
    --secret-id fuel-flow-rds-password-dev \
    --query SecretString --output text
  ```

## Option 2: CloudFormation Deployment

### Step 1: Configure AWS Credentials

```bash
aws configure
```

### Step 2: Deploy Stacks in Order

```bash
cd cloudformation

# 1. Deploy IAM roles first
aws cloudformation create-stack \
  --stack-name fuel-flow-iam-dev \
  --template-body file://iam-roles.yaml \
  --parameters ParameterKey=Environment,ParameterValue=dev \
  --capabilities CAPABILITY_NAMED_IAM

# 2. Deploy S3 buckets
aws cloudformation create-stack \
  --stack-name fuel-flow-s3-dev \
  --template-body file://s3-buckets.yaml \
  --parameters ParameterKey=Environment,ParameterValue=dev

# 3. Deploy RDS database
aws cloudformation create-stack \
  --stack-name fuel-flow-rds-dev \
  --template-body file://rds-database.yaml \
  --parameters ParameterKey=Environment,ParameterValue=dev
```

### Step 3: Monitor Stack Creation

```bash
aws cloudformation wait stack-create-complete \
  --stack-name fuel-flow-ec2-dev

aws cloudformation describe-stacks \
  --stack-name fuel-flow-ec2-dev \
  --query 'Stacks[0].Outputs'
```

## Common Tasks

### Connect to EC2 Instance

```bash
# Get the public IP
terraform output ec2_public_ips
# or for CloudFormation:
aws cloudformation describe-stacks \
  --stack-name fuel-flow-ec2-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`PublicIp1`].OutputValue' \
  --output text

# SSH (if you configured a key pair)
ssh -i ~/.ssh/your-key.pem ec2-user@<public-ip>
```

### Access RDS Database Password

```bash
# Get the secret ARN
terraform output rds_database_name

# Retrieve the password
aws secretsmanager get-secret-value \
  --secret-id fuel-flow-rds-password-dev \
  --query SecretString --output text | jq -r .password
```

### View All Resources

```bash
# Terraform
terraform state list

# CloudFormation
aws cloudformation describe-stack-resources \
  --stack-name fuel-flow-ec2-dev
```

## Cleanup

### Terraform

```bash
cd terraform
terraform destroy
```

### CloudFormation

Delete stacks in reverse order:

```bash
aws cloudformation delete-stack --stack-name fuel-flow-rds-dev
aws cloudformation delete-stack --stack-name fuel-flow-ec2-dev
aws cloudformation delete-stack --stack-name fuel-flow-s3-dev
aws cloudformation delete-stack --stack-name fuel-flow-iam-dev
```

## Troubleshooting

### Issue: Terraform state locked

**Solution:**
```bash
# Get the lock ID from the error message
terraform force-unlock <LOCK_ID>
```

### Issue: CloudFormation stack stuck

**Solution:**
```bash
# Check events for errors
aws cloudformation describe-stack-events \
  --stack-name <stack-name> \
  --max-items 20

# Delete with retained resources if needed
aws cloudformation delete-stack \
  --stack-name <stack-name> \
  --retain-resources <resource-id>
```

### Issue: AWS credentials not working

**Solution:**
```bash
# Verify credentials
aws sts get-caller-identity

# If needed, reconfigure
aws configure
```

### Issue: EC2 instance not accessible

**Solution:**
- Check security group allows HTTP (port 80) from your IP
- Verify instance is running: `aws ec2 describe-instances`
- Check user data logs: SSH to instance and check `/var/log/cloud-init-output.log`

## Next Steps

1. **Customize**: Edit `terraform.tfvars` or CloudFormation parameters for your needs
2. **Scale**: Increase instance counts or sizes
3. **Secure**: Add VPN or bastion host for production
4. **Monitor**: Enable CloudWatch alarms and dashboards
5. **Backup**: Configure automated backup policies
6. **CI/CD**: Integrate with your deployment pipeline

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS CloudFormation Documentation](https://docs.aws.amazon.com/cloudformation/)
- [AWS CLI Command Reference](https://docs.aws.amazon.com/cli/latest/reference/)

## Support

For issues or questions, please open an issue in this repository.
