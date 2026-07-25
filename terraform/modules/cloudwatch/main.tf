resource "aws_kms_key" "log_group_encryption" {
  description             = "KMS key for Lambda CloudWatch log group encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 10
  tags                    = var.tags
}

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
