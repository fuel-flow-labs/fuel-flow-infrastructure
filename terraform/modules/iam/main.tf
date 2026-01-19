# IAM Module
# Creates IAM roles and policies

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "fuel-flow-ec2-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "fuel-flow-ec2-role-${var.environment}"
    Environment = var.environment
  }
}

# IAM Policy for EC2 to access S3
resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "ec2-s3-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::fuel-flow-${var.environment}-*",
          "arn:aws:s3:::fuel-flow-${var.environment}-*/*"
        ]
      }
    ]
  })
}

# IAM Policy for EC2 CloudWatch Logs
resource "aws_iam_role_policy" "ec2_cloudwatch_policy" {
  name = "ec2-cloudwatch-logs"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "fuel-flow-ec2-profile-${var.environment}"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name        = "fuel-flow-ec2-profile-${var.environment}"
    Environment = var.environment
  }
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring_role" {
  name = "fuel-flow-rds-monitoring-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "fuel-flow-rds-monitoring-role-${var.environment}"
    Environment = var.environment
  }
}

# Attach AWS managed policy for RDS Enhanced Monitoring
resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
