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
│  │  │ Lambda        │         │  RDS PostgreSQL  │          │  │
│  │  │ Functions     │         │  Database        │          │  │
│  │  │               │────────▶│                  │          │  │
│  │  │  - Node.js    │         │  - Encrypted     │          │  │
│  │  │  - IAM Role   │         │  - Multi-AZ      │          │  │
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
│  │  • Lambda Execution Role (S3 + VPC + CloudWatch access)  │  │
│  │  • RDS Monitoring Role (Enhanced Monitoring)             │  │
│  │  • API Gateway Invocation (Logs access)                  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

      ▲
      │
      │ HTTP/HTTPS
      │
┌─────┴──────┐
│ API Gateway│
│ REST API   │
└────────────┘
```

## Resource Relationships

### IAM Dependencies
```
IAM Roles
  ├─► Lambda Execution Role ──► Lambda Functions
  └─► RDS Monitoring Role ──► RDS Instance
```

### Storage Dependencies
```
S3 Buckets
  ├─► Application Data Bucket
  │     └─► Accessed by Lambda Functions via IAM Role
  ├─► Logs Bucket
  │     └─► CloudWatch logs, Application logs
  └─► Backups Bucket
        └─► RDS automated backups, Manual snapshots
```

### Compute & Database
```
Lambda Functions
  ├─► Connect to RDS PostgreSQL
  ├─► Read/Write to S3 Buckets
  ├─► Send logs to CloudWatch
  └─► Invoked by API Gateway

API Gateway
  ├─► Routes requests to Lambda
  ├─► Handles authentication/authorization
  └─► Logs to CloudWatch

RDS PostgreSQL Instance
  ├─► Password in Secrets Manager
  ├─► Automated backups to S3
  ├─► Logs to CloudWatch
  └─► Accessible from Lambda in VPC
```

## Security Architecture

### Network Security

```
Internet
    │
    ▼
API Gateway (HTTPS)
    │
    ▼
Lambda Functions (in VPC)
    │
    ▼ (Within VPC)
Security Group (RDS)
├─ Inbound: PostgreSQL (5432) from VPC CIDR only
└─ Outbound: All traffic
    │
    ▼
RDS PostgreSQL Instance
```

### Identity & Access Management

1. **Lambda Execution Role**
   - S3 read/write access (scoped to fuel-flow buckets)
   - CloudWatch logs write access
   - VPC access for RDS connectivity
   - Secrets Manager read access

2. **RDS Monitoring Role**
   - Enhanced monitoring metrics to CloudWatch
   - Managed by AWS

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
- **Lambda**: Auto-scaling, serverless (no instances to manage)
- **S3**: 99.999999999% durability (11 nines)
- **Backups**: 7-day automated RDS backups

### Recommended Production Enhancements
```
Production Improvements:
├─ Multi-AZ RDS deployment
├─ Lambda Reserved Concurrency
├─ API Gateway Custom Domain + CloudFront
├─ WAF for API Gateway
├─ VPC Endpoints for S3/Secrets Manager
└─ Route53 for DNS management
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
    │   ├── main.tf              # Lambda, RDS roles
    │   ├── variables.tf
    │   └── outputs.tf
    ├── s3/                      # S3 buckets
    │   ├── main.tf              # App data, logs, backups
    │   ├── variables.tf
    │   └── outputs.tf
    ├── lambda/                  # Lambda functions
    │   ├── main.tf              # Serverless functions
    │   ├── variables.tf
    │   └── outputs.tf
    ├── api-gateway/             # API Gateway
    │   ├── main.tf              # REST API configuration
    │   ├── variables.tf
    │   └── outputs.tf
    └── rds/                     # RDS database
        ├── main.tf              # PostgreSQL instance + secrets
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

3. RDS Stack (rds-database.yaml)
   └─► Creates: Database + VPC + Subnets + Secrets

Note: EC2 template (ec2-instances.yaml) is legacy and kept for reference
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
   ├─► module.api_gateway (creates API Gateway)
   ├─► module.lambda (creates functions) [depends on IAM, API Gateway]
   └─► module.rds (creates database)
```

### CloudFormation Workflow
```
Stack Creation Sequence:
   │
   ├─► fuel-flow-iam-dev
   │     └─► Exports: Role ARNs
   │
   ├─► fuel-flow-s3-dev
   │     └─► Exports: Bucket names
   │
   └─► fuel-flow-rds-dev
         └─► Exports: Endpoint, Secret ARN
```

## Cost Estimation (Approximate Monthly)

### Development Environment
- Lambda (1M requests/mo): ~$0.20
- API Gateway (1M requests): ~$3.50
- RDS db.t3.micro (single-AZ): ~$12
- S3 storage (minimal): ~$0.50
- DynamoDB (on-demand): ~$0.10
- Secrets Manager: ~$0.40
- **Total: ~$17/month**

### Production Environment (Estimated)
- Lambda (10M requests/mo): ~$2.00
- API Gateway (10M requests): ~$35
- RDS db.t3.small (multi-AZ): ~$48
- S3 storage (100GB): ~$2.30
- DynamoDB (on-demand): ~$0.25
- CloudWatch: ~$3
- Secrets Manager: ~$0.40
- Data transfer: ~$5
- **Total: ~$96/month**

## Monitoring & Observability

### CloudWatch Metrics
- Lambda: Invocations, Duration, Errors, Throttles
- API Gateway: Request count, Latency, Errors
- RDS: CPU, Connections, Storage, Replication lag
- S3: Bucket size, Request metrics
- DynamoDB: Read/Write capacity, Throttles

### CloudWatch Logs
- Lambda function logs
- API Gateway access logs
- RDS error, general, and slow query logs
- CloudFormation/Terraform deployment logs

### Recommended Alarms
- Lambda errors > 1%
- Lambda duration > 80% of timeout
- API Gateway 5XX errors
- RDS Storage < 10% free
- RDS CPU > 80%
- DynamoDB throttled requests

## Scaling Considerations

### Horizontal Scaling
- Lambda auto-scales automatically (up to account limits)
- Configure Reserved Concurrency for predictable workloads
- Use Provisioned Concurrency for consistent performance

### Vertical Scaling
- Increase Lambda memory allocation (also increases CPU)
- Increase RDS instance class
- Increase RDS storage

### Database Scaling
- Read replicas for read-heavy workloads
- Aurora Serverless for variable workloads
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
