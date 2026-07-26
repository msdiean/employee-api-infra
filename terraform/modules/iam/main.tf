resource "aws_iam_role" "lambda_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.role_name}-policy"
  description = "Policy to allow Lambda access to DynamoDB and CloudWatch Logs."
  policy      = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      var.dynamodb_table_arn,
      "${var.dynamodb_table_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = ["arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}
