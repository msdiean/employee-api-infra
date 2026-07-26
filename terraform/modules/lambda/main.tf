resource "aws_sqs_queue" "lambda_dlq" {
  name                    = "${var.function_name}-dlq"
  sqs_managed_sse_enabled = true
  tags                    = var.tags
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn
  handler       = var.handler
  runtime       = var.runtime
  filename      = abspath(var.source_code_path)
  memory_size   = var.memory_size
  timeout       = var.timeout
  publish       = true

  environment {
    variables = var.environment_variables
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  tracing_config {
    mode = "Active"
  }

  tags = var.tags

  source_code_hash = filebase64sha256(abspath(var.source_code_path))

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash
    ]
  }
}
