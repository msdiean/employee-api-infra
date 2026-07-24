resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn
  handler       = var.handler
  runtime       = var.runtime
  filename      = var.source_code_path
  memory_size   = var.memory_size
  timeout       = var.timeout
  publish       = true

  environment {
    variables = var.environment_variables
  }

  tags = var.tags

  source_code_hash = filebase64sha256(var.source_code_path)
}
