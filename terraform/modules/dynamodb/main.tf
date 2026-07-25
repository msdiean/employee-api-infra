resource "aws_kms_key" "table_encryption" {
  description             = "KMS key for DynamoDB table encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 10
  tags                    = var.tags
}

resource "aws_kms_alias" "table_encryption" {
  name          = "alias/${replace(replace(replace(var.table_name, "/", ""), "-", ""), "_", "")}-table"
  target_key_id = aws_kms_key.table_encryption.key_id
}

resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "employeeId"

  attribute {
    name = "employeeId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.table_encryption.arn
  }

  tags = var.tags
}
