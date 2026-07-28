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

# 3. Zip package for inline Node.js Auto-Rollback Lambda
data "archive_file" "rollback_zip" {
  type        = "zip"
  output_path = "${path.module}/rollback_handler.zip"

  source {
    content  = <<EOF
const { LambdaClient, ListVersionsByFunctionCommand, UpdateAliasCommand } = require("@aws-sdk/client-lambda");

exports.handler = async (event) => {
  console.log("Auto-Rollback Triggered by Alarm Event:", JSON.stringify(event));
  const lambda = new LambdaClient({});
  const functionName = process.env.TARGET_FUNCTION_NAME;
  const aliasName = process.env.TARGET_ALIAS_NAME;

  try {
    const versionsRes = await lambda.send(new ListVersionsByFunctionCommand({ FunctionName: functionName }));
    const versions = (versionsRes.Versions || [])
      .map(v => parseInt(v.Version, 10))
      .filter(v => !isNaN(v))
      .sort((a, b) => b - a);

    if (versions.length < 2) {
      console.log("No previous version available to roll back to.");
      return;
    }

    const previousVersion = String(versions[1]);
    console.log("Rolling back alias '" + aliasName + "' on function '" + functionName + "' to Version: " + previousVersion);

    await lambda.send(new UpdateAliasCommand({
      FunctionName: functionName,
      Name: aliasName,
      FunctionVersion: previousVersion
    }));

    console.log("Auto-Rollback completed successfully.");
  } catch (err) {
    console.error("Auto-Rollback failed:", err);
    throw err;
  }
};
EOF
    filename = "index.js"
  }
}

# 4. Auto-Rollback Lambda Function
resource "aws_lambda_function" "auto_rollback" {
  function_name    = "${var.function_name}-auto-rollback"
  role             = aws_iam_role.rollback_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.rollback_zip.output_path
  source_code_hash = data.archive_file.rollback_zip.output_base64sha256
  timeout          = 30

  depends_on = [
    data.archive_file.rollback_zip
  ]

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


