# S3 Module
# Creates application S3 buckets

locals {
  bucket_suffix = "${var.bucket_prefix}-${var.environment}"
}

resource "aws_s3_bucket" "app_data" {
  bucket = "${local.bucket_suffix}-app-data"

  tags = {
    Name        = "${local.bucket_suffix}-app-data"
    Environment = var.environment
    Purpose     = "Application Data"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "${local.bucket_suffix}-logs"

  tags = {
    Name        = "${local.bucket_suffix}-logs"
    Environment = var.environment
    Purpose     = "Application Logs"
  }
}

resource "aws_s3_bucket" "backups" {
  bucket = "${local.bucket_suffix}-backups"

  tags = {
    Name        = "${local.bucket_suffix}-backups"
    Environment = var.environment
    Purpose     = "Backups"
  }
}

# Enable versioning for app data bucket
resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable versioning for backups bucket
resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access for all buckets
resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable encryption for all buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
