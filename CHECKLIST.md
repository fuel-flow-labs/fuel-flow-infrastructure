# Pre-Deployment Checklist

Use this checklist before deploying infrastructure to ensure everything is configured correctly.

## Prerequisites

- [ ] AWS Account created and accessible
- [ ] AWS CLI installed (`aws --version`)
- [ ] AWS credentials configured (`aws sts get-caller-identity`)
- [ ] Terraform installed (for Terraform deployment) (`terraform --version`)
- [ ] Git repository cloned locally
- [ ] Sufficient AWS permissions (AdministratorAccess or equivalent)

## Configuration Review

### Terraform Configuration

- [ ] Reviewed `terraform/variables.tf` for default values
- [ ] Created `terraform/terraform.tfvars` from example file
- [ ] Updated `terraform.tfvars` with environment-specific values:
  - [ ] `aws_region` matches your preferred region
  - [ ] `environment` is set (dev/staging/prod)
  - [ ] `ec2_key_name` is set (if SSH access needed)
  - [ ] S3 bucket names are unique globally
  - [ ] Instance types match budget requirements
- [ ] Reviewed `terraform/backend.tf` configuration
- [ ] Understand state backend setup process

### CloudFormation Configuration

- [ ] Reviewed CloudFormation template parameters
- [ ] Prepared parameter values for each stack:
  - [ ] Environment name (dev/staging/prod)
  - [ ] Instance types
  - [ ] Key pair name (if needed)
  - [ ] Database configuration
- [ ] Understand stack deployment order

## Security Checklist

- [ ] `.gitignore` file present and configured
- [ ] Will not commit sensitive files:
  - [ ] `*.tfvars` files
  - [ ] `*.tfstate` files
  - [ ] `.terraform/` directory
  - [ ] `*.pem` key files
- [ ] Understand AWS Secrets Manager usage for passwords
- [ ] Plan for key pair management (EC2 SSH access)
- [ ] Reviewed IAM role permissions
- [ ] Understand security group configurations

## Cost Management

- [ ] Reviewed estimated costs in ARCHITECTURE.md
- [ ] Selected appropriate instance types for budget:
  - [ ] EC2 instance type: `t3.micro` (dev) or larger (prod)
  - [ ] RDS instance class: `db.t3.micro` (dev) or larger (prod)
- [ ] Understand AWS Free Tier limitations
- [ ] Plan to set up AWS Budget alerts
- [ ] Plan to tag resources for cost tracking

## Backup and Disaster Recovery

- [ ] Understand RDS automated backup schedule (7 days default)
- [ ] S3 versioning enabled for critical buckets
- [ ] Plan for manual snapshots (if needed)
- [ ] Understand data retention requirements
- [ ] Know how to restore from backups

## Deployment Plan

### For Terraform

- [ ] Understand two-phase deployment:
  1. [ ] Deploy terraform_state module first
  2. [ ] Migrate to remote backend (optional)
  3. [ ] Deploy remaining infrastructure
- [ ] Have rollback plan if deployment fails
- [ ] Understand how to destroy resources

### For CloudFormation

- [ ] Understand stack deployment order:
  1. [ ] IAM roles first
  2. [ ] S3 buckets second
  3. [ ] EC2 instances third
  4. [ ] RDS database last
- [ ] Know how to check stack status
- [ ] Understand how to delete stacks

## Validation After Deployment

### Terraform Validation

- [ ] Run `terraform plan` shows expected resources
- [ ] No errors during `terraform apply`
- [ ] All modules deployed successfully
- [ ] Output values visible (`terraform output`)
- [ ] State file created (local or remote)

### CloudFormation Validation

- [ ] All stacks show CREATE_COMPLETE status
- [ ] Stack outputs available
- [ ] No rollback occurred
- [ ] Resources visible in AWS Console

### Resource Validation

- [ ] S3 buckets created and accessible
  ```bash
  aws s3 ls | grep fuel-flow
  ```

- [ ] EC2 instances running
  ```bash
  aws ec2 describe-instances --filters "Name=tag:Project,Values=fuel-flow"
  ```

- [ ] RDS instance available
  ```bash
  aws rds describe-db-instances | grep fuel-flow
  ```

- [ ] IAM roles created
  ```bash
  aws iam list-roles | grep fuel-flow
  ```

- [ ] Secrets in Secrets Manager
  ```bash
  aws secretsmanager list-secrets | grep fuel-flow
  ```

### Functional Testing

- [ ] Can access EC2 instance via HTTP (public IP)
- [ ] EC2 instance shows "Fuel Flow" test page
- [ ] Can SSH to EC2 (if key pair configured)
- [ ] Can retrieve RDS password from Secrets Manager
- [ ] EC2 instance can write to S3 buckets
- [ ] RDS instance is accessible from EC2
- [ ] CloudWatch logs are being generated

## Post-Deployment Tasks

- [ ] Document deployed resource IDs/names
- [ ] Set up CloudWatch alarms
- [ ] Configure backup schedules (if different from default)
- [ ] Test disaster recovery procedures
- [ ] Update DNS records (if applicable)
- [ ] Set up monitoring dashboards
- [ ] Configure log retention policies
- [ ] Review and optimize costs
- [ ] Document any customizations made
- [ ] Train team on infrastructure management

## Common Issues and Solutions

### Issue: S3 bucket name already exists
**Solution**: S3 bucket names must be globally unique. Change `s3_bucket_prefix` in variables.

### Issue: Terraform state locked
**Solution**: Wait for concurrent operations to complete, or use `terraform force-unlock <ID>`

### Issue: Insufficient AWS permissions
**Solution**: Verify IAM user/role has required permissions (AdministratorAccess recommended for initial setup)

### Issue: EC2 instance not accessible
**Solution**: 
- Check security group allows traffic
- Verify instance is running
- Check route tables and internet gateway

### Issue: RDS connection timeout
**Solution**:
- RDS is only accessible from within VPC
- Connect from EC2 instance, not from internet

### Issue: CloudFormation stack rollback
**Solution**:
- Check stack events for error details
- Fix parameter issues
- Ensure resource limits not exceeded

## Emergency Procedures

### Roll Back Deployment

**Terraform:**
```bash
# Destroy specific module
terraform destroy -target=module.ec2

# Destroy everything
terraform destroy
```

**CloudFormation:**
```bash
# Delete specific stack
aws cloudformation delete-stack --stack-name fuel-flow-ec2-dev

# Delete all stacks (in reverse order)
aws cloudformation delete-stack --stack-name fuel-flow-rds-dev
aws cloudformation delete-stack --stack-name fuel-flow-ec2-dev
aws cloudformation delete-stack --stack-name fuel-flow-s3-dev
aws cloudformation delete-stack --stack-name fuel-flow-iam-dev
```

### Data Recovery

**S3:**
```bash
# List versions
aws s3api list-object-versions --bucket fuel-flow-dev-app-data

# Restore previous version
aws s3api copy-object \
  --copy-source fuel-flow-dev-app-data/file.txt?versionId=VERSION_ID \
  --bucket fuel-flow-dev-app-data \
  --key file.txt
```

**RDS:**
```bash
# List automated snapshots
aws rds describe-db-snapshots --db-instance-identifier fuel-flow-db-dev

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier fuel-flow-db-dev-restored \
  --db-snapshot-identifier snapshot-name
```

## Additional Resources

- [ ] Bookmarked AWS Console
- [ ] Saved AWS CLI configuration
- [ ] Noted support contacts
- [ ] Documented architecture decisions
- [ ] Stored credentials securely

## Sign-Off

Deployment completed by: ___________________________

Date: ___________________________

Environment: ___________________________

Notes: _______________________________________________
