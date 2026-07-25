resource "aws_kms_key" "lambda_environment" {
  description             = "KMS key for Lambda environment variables"
  enable_key_rotation     = true
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.kms_policy.json
  tags                    = var.tags
}

data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow Lambda to use the key"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_kms_alias" "lambda_environment" {
  name          = "alias/${replace(replace(replace(var.function_name, "/", ""), "-", ""), "_", "")}-lambda-env"
  target_key_id = aws_kms_key.lambda_environment.key_id
}

resource "aws_sqs_queue" "lambda_dlq" {
  name                      = "${var.function_name}-dlq"
  sqs_managed_sse_enabled   = true
  tags                      = var.tags
}

resource "aws_signer_signing_profile" "this" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = replace("${var.function_name}-signing-profile", "-", "_")
}

resource "aws_lambda_code_signing_config" "this" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.this.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

resource "aws_lambda_function" "this" {
  function_name                  = var.function_name
  role                           = var.role_arn
  handler                        = var.handler
  runtime                        = var.runtime
  filename                       = var.source_code_path
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  publish                        = true
  # KMS encryption temporarily disabled for initial deployment
  # kms_key_arn                    = aws_kms_key.lambda_environment.arn
  reserved_concurrent_executions = 1
  code_signing_config_arn        = aws_lambda_code_signing_config.this.arn

  environment {
    variables = var.environment_variables
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  tags = var.tags

  source_code_hash = fileexists(var.source_code_path) ? filebase64sha256(var.source_code_path) : base64sha256("placeholder")
}
