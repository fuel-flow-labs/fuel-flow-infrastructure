output "bucket_names" {
  description = "Names of created S3 buckets"
  value = {
    app_data = aws_s3_bucket.app_data.id
    logs     = aws_s3_bucket.logs.id
    backups  = aws_s3_bucket.backups.id
  }
}

output "bucket_arns" {
  description = "ARNs of created S3 buckets"
  value = {
    app_data = aws_s3_bucket.app_data.arn
    logs     = aws_s3_bucket.logs.arn
    backups  = aws_s3_bucket.backups.arn
  }
}
