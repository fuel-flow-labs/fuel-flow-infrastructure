# Lambda Module
# Creates Lambda functions for microservices

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  
  source {
    content  = <<-EOT
      exports.handler = async (event) => {
        return {
          statusCode: 200,
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: 'Fuel Flow API - Environment: ${var.environment}',
            timestamp: new Date().toISOString(),
          }),
        };
      };
    EOT
    filename = "index.js"
  }
}

# Lambda Function for API
resource "aws_lambda_function" "api" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "fuel-flow-api-${var.environment}"
  role            = var.lambda_role_arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "nodejs20.x"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      ENVIRONMENT = var.environment
      DB_ENDPOINT = var.db_endpoint
      DB_NAME     = var.db_name
    }
  }

  tags = {
    Name        = "fuel-flow-api-${var.environment}"
    Environment = var.environment
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.api.function_name}"
  retention_in_days = 7

  tags = {
    Name        = "fuel-flow-lambda-logs-${var.environment}"
    Environment = var.environment
  }
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}
