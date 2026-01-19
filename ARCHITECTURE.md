# Architecture Overview

## Infrastructure Components

The Fuel Flow infrastructure consists of the following AWS components:

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud Account                        │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    VPC (Default)                           │  │
│  │                                                             │  │
│  │  ┌───────────────┐         ┌──────────────────┐          │  │
│  │  │  EC2 Instance │         │  RDS MySQL       │          │  │
│  │  │               │         │  Database        │          │  │
│  │  │  - Apache     │────────▶│                  │          │  │
│  │  │  - IAM Role   │         │  - Encrypted     │          │  │
│  │  │               │         │  - Multi-AZ      │          │  │
│  │  └───────┬───────┘         └──────────────────┘          │  │
│  │          │                                                 │  │
│  │          │ Access                                          │  │
│  │          ▼                                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│             │                                                   │
│             │                                                   │
│  ┌──────────▼───────────────────────────────────────────────┐  │
│  │                   S3 Buckets                              │  │
│  │                                                            │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │  │
│  │  │  App Data    │  │    Logs      │  │   Backups    │  │  │
│  │  │  - Versioned │  │  - Encrypted │  │  - Versioned │  │  │
│  │  │  - Encrypted │  │              │  │  - Encrypted │  │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Terraform State Management                   │  │
│  │                                                            │  │
│  │  ┌──────────────┐            ┌──────────────────┐       │  │
│  │  │  S3 Bucket   │            │  DynamoDB Table  │       │  │
│  │  │  (State)     │            │  (Locking)       │       │  │
│  │  │  - Versioned │            │  - LockID (PK)   │       │  │
│  │  │  - Encrypted │            │                  │       │  │
│  │  └──────────────┘            └──────────────────┘       │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  AWS Secrets Manager                      │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────┐           │  │
│  │  │  RDS Database Password                   │           │  │
│  │  │  - Auto-generated                        │           │  │
│  │  │  - Encrypted                             │           │  │
│  │  └──────────────────────────────────────────┘           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     IAM Roles                             │  │
│  │                                                            │  │
│  │  • EC2 Instance Role (S3 + CloudWatch access)            │  │
│  │  • RDS Monitoring Role (Enhanced Monitoring)             │  │
│  │  • Lambda Execution Role (S3 + Logs access)              │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Resource Relationships

### IAM Dependencies
```
IAM Roles
  ├─► EC2 Instance Profile ──► EC2 Instances
  ├─► RDS Monitoring Role ──► RDS Instance
  └─► Lambda Execution Role
```

### Storage Dependencies
```
S3 Buckets
  ├─► Application Data Bucket
  │     └─► Accessed by EC2 Instances via IAM Role
  ├─► Logs Bucket
  │     └─► CloudWatch logs, Application logs
  └─► Backups Bucket
        └─► RDS automated backups, Manual snapshots
```

### Compute & Database
```
EC2 Instances
  ├─► Connect to RDS MySQL
  ├─► Read/Write to S3 Buckets
  ├─► Send logs to CloudWatch
  └─► Accessible via HTTP/HTTPS

RDS MySQL Instance
  ├─► Password in Secrets Manager
  ├─► Automated backups to S3
  ├─► Logs to CloudWatch
  └─► Accessible from EC2 in VPC
```

## Security Architecture

### Network Security

```
Internet
    │
    ▼
Security Group (EC2)
├─ Inbound: SSH (22), HTTP (80), HTTPS (443)
└─ Outbound: All traffic
    │
    ▼
EC2 Instance(s)
    │
    ▼ (Within VPC)
Security Group (RDS)
├─ Inbound: MySQL (3306) from VPC CIDR only
└─ Outbound: All traffic
    │
    ▼
RDS MySQL Instance
```

### Identity & Access Management

1. **EC2 Instance Role**
   - S3 read/write access (scoped to fuel-flow buckets)
   - CloudWatch logs write access
   - No direct AWS API access

2. **RDS Monitoring Role**
   - Enhanced monitoring metrics to CloudWatch
   - Managed by AWS

3. **Lambda Execution Role**
   - Basic Lambda execution
   - S3 access for data processing
   - CloudWatch logs

### Data Encryption

- **At Rest**:
  - S3: AES-256 server-side encryption
  - RDS: Encrypted storage (GP3)
  - Secrets Manager: Encrypted secrets

- **In Transit**:
  - HTTPS for S3 access
  - SSL/TLS for RDS connections
  - VPC internal communication

## High Availability & Disaster Recovery

### Current Architecture
- **RDS**: Single-AZ (dev), configurable Multi-AZ (prod)
- **EC2**: Single instance (dev), scalable to multiple instances
- **S3**: 99.999999999% durability (11 nines)
- **Backups**: 7-day automated RDS backups

### Recommended Production Enhancements
```
Production Improvements:
├─ Auto Scaling Group for EC2
├─ Application Load Balancer
├─ Multi-AZ RDS deployment
├─ CloudFront for S3 content delivery
├─ Route53 for DNS management
└─ AWS WAF for web application firewall
```

## Terraform Module Structure

```
terraform/
├── main.tf                      # Root module orchestration
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── backend.tf                   # State backend configuration
└── modules/
    ├── terraform-state/         # State backend infrastructure
    │   ├── main.tf              # S3 bucket + DynamoDB table
    │   ├── variables.tf
    │   └── outputs.tf
    ├── iam/                     # IAM roles and policies
    │   ├── main.tf              # EC2, RDS, Lambda roles
    │   ├── variables.tf
    │   └── outputs.tf
    ├── s3/                      # S3 buckets
    │   ├── main.tf              # App data, logs, backups
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ec2/                     # EC2 instances
    │   ├── main.tf              # Instances + security groups
    │   ├── variables.tf
    │   └── outputs.tf
    └── rds/                     # RDS database
        ├── main.tf              # MySQL instance + secrets
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

## CloudFormation Stack Architecture

```
Deployment Order:
1. IAM Stack (iam-roles.yaml)
   └─► Creates all IAM roles needed by other stacks

2. S3 Stack (s3-buckets.yaml)
   └─► Creates storage buckets

3. EC2 Stack (ec2-instances.yaml)
   ├─► References: IAM Stack outputs
   └─► Creates: Instances + Security Groups

4. RDS Stack (rds-database.yaml)
   └─► Creates: Database + VPC + Subnets + Secrets
```

## Deployment Workflows

### Terraform Workflow
```
terraform init
   │
   ▼
terraform plan
   │
   ▼
terraform apply
   │
   ├─► module.terraform_state (creates state backend)
   ├─► module.iam (creates IAM roles)
   ├─► module.s3 (creates S3 buckets)
   ├─► module.ec2 (creates instances) [depends on IAM]
   └─► module.rds (creates database)
```

### CloudFormation Workflow
```
Stack Creation Sequence:
   │
   ├─► fuel-flow-iam-dev
   │     └─► Exports: Role ARNs, Instance Profile
   │
   ├─► fuel-flow-s3-dev
   │     └─► Exports: Bucket names
   │
   ├─► fuel-flow-ec2-dev
   │     ├─► Imports: IAM outputs
   │     └─► Exports: Instance IDs, IPs
   │
   └─► fuel-flow-rds-dev
         └─► Exports: Endpoint, Secret ARN
```

## Cost Estimation (Approximate Monthly)

### Development Environment
- EC2 t3.micro (1 instance): ~$7.50
- RDS db.t3.micro (single-AZ): ~$12
- S3 storage (minimal): ~$0.50
- DynamoDB (on-demand): ~$0.10
- Secrets Manager: ~$0.40
- **Total: ~$20.50/month**

### Production Environment (Estimated)
- EC2 t3.small (2 instances): ~$30
- RDS db.t3.small (multi-AZ): ~$48
- S3 storage (100GB): ~$2.30
- DynamoDB (on-demand): ~$0.25
- Application Load Balancer: ~$16
- CloudWatch: ~$3
- Secrets Manager: ~$0.40
- Data transfer: ~$5
- **Total: ~$105/month**

## Monitoring & Observability

### CloudWatch Metrics
- EC2: CPU, Memory, Network, Disk
- RDS: CPU, Connections, Storage, Replication lag
- S3: Bucket size, Request metrics
- DynamoDB: Read/Write capacity, Throttles

### CloudWatch Logs
- EC2 system logs
- Apache access/error logs
- RDS error, general, and slow query logs
- CloudFormation/Terraform deployment logs

### Recommended Alarms
- EC2 CPU > 80%
- RDS Storage < 10% free
- RDS CPU > 80%
- DynamoDB throttled requests
- High error rates

## Scaling Considerations

### Horizontal Scaling
- Add more EC2 instances
- Use Auto Scaling Groups
- Implement Application Load Balancer

### Vertical Scaling
- Increase EC2 instance type
- Increase RDS instance class
- Increase RDS storage

### Database Scaling
- Read replicas for read-heavy workloads
- Aurora for better performance
- ElastiCache for caching layer

## Security Best Practices Implemented

✅ All S3 buckets block public access
✅ S3 encryption at rest enabled
✅ RDS encryption at rest enabled
✅ Database passwords in Secrets Manager
✅ IAM roles with least privilege
✅ Security groups with minimal required access
✅ Terraform state encryption enabled
✅ Versioning enabled for critical buckets
✅ CloudWatch logs export enabled
✅ Automated backups configured

## Additional Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
