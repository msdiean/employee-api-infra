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
  layers = var.datadog_api_key_secret_arn != "" ? [
    "arn:aws:lambda:ap-south-1:464270061747:layer:Datadog-Extension:63"
  ] : []

  environment {
    variables = merge(
      var.environment_variables,
      var.datadog_api_key_secret_arn != "" ? {
        DD_API_KEY_SECRET_ARN = var.datadog_api_key_secret_arn
        DD_SITE               = "datadoghq.com"
        DD_ENV                = "dev"
        DD_SERVICE            = var.function_name
        DD_TRACE_ENABLED      = "true"
        DD_LOGS_INJECTION     = "true"
      } : {}
    )
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  tracing_config {
    mode = "Active"
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
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

resource "aws_lambda_alias" "live" {
  name             = "live"
  description      = "Live alias pointing to the latest published version"
  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version

  lifecycle {
    ignore_changes = [
      function_version,
      routing_config
    ]
  }
}

# 1. CloudWatch Metric Alarm monitoring Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.function_name}-errors-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Triggers when Lambda function encounters runtime errors"

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }

  tags = var.tags
}

# 2. IAM Role for the Auto-Rollback Handler Lambda
resource "aws_iam_role" "rollback_lambda" {
  name = "${var.function_name}-auto-rollback-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "rollback_lambda_policy" {
  name = "${var.function_name}-auto-rollback-policy"
  role = aws_iam_role.rollback_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:GetAlias",
          "lambda:UpdateAlias",
          "lambda:ListVersionsByFunction"
        ]
        Resource = "arn:aws:lambda:*:*:function:${aws_lambda_function.this.function_name}*"
      }
    ]
  })
}

# 3. Auto-Rollback Lambda Function
resource "aws_lambda_function" "auto_rollback" {
  function_name    = "${var.function_name}-auto-rollback"
  role             = aws_iam_role.rollback_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = "${path.module}/rollback_handler.zip"
  source_code_hash = filebase64sha256("${path.module}/rollback_handler.zip")
  timeout          = 30

  environment {
    variables = {
      TARGET_FUNCTION_NAME = aws_lambda_function.this.function_name
      TARGET_ALIAS_NAME    = aws_lambda_alias.live.name
    }
  }

  tags = var.tags
}

# 5. EventBridge Rule listening for CloudWatch Alarm in ALARM state
resource "aws_cloudwatch_event_rule" "alarm_rule" {
  name        = "${var.function_name}-alarm-rollback-rule"
  description = "Triggers auto-rollback Lambda when CloudWatch error alarm fires"

  event_pattern = jsonencode({
    source        = ["aws.cloudwatch"],
    "detail-type" = ["CloudWatch Alarm State Change"],
    resources     = [aws_cloudwatch_metric_alarm.lambda_errors.arn],
    detail = {
      state = {
        value = ["ALARM"]
      }
    }
  })

  tags = var.tags
}

# 6. EventBridge Target connecting Alarm Rule to Auto-Rollback Lambda
resource "aws_cloudwatch_event_target" "trigger_rollback" {
  rule      = aws_cloudwatch_event_rule.alarm_rule.name
  target_id = "TriggerAutoRollbackLambda"
  arn       = aws_lambda_function.auto_rollback.arn
}

# 7. Lambda Permission allowing EventBridge to invoke Auto-Rollback Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_rollback.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.alarm_rule.arn
}


