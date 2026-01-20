variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_role_arn" {
  description = "IAM role ARN for Lambda execution"
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for Lambda permission"
  type        = string
}

variable "db_endpoint" {
  description = "RDS database endpoint"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "RDS database name"
  type        = string
  default     = ""
}
