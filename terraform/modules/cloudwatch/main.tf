resource "aws_kms_key" "log_group_encryption" {
  description             = "KMS key for Lambda CloudWatch log group encryption"
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
    sid    = "Allow CloudWatch Logs to use the key"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
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

resource "aws_kms_alias" "log_group_encryption" {
  name          = "alias/${replace(replace(replace(var.log_group_name, "/", ""), "-", ""), "_", "")}-logs"
  target_key_id = aws_kms_key.log_group_encryption.key_id
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days
  kms_key_id        = aws_kms_key.log_group_encryption.arn
  tags              = var.tags
}
