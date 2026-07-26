resource "aws_s3_bucket" "central_audit" {
  bucket        = var.bucket_name
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_website_configuration" "central_audit" {
  bucket = aws_s3_bucket.central_audit.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "central_audit" {
  bucket = aws_s3_bucket.central_audit.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "central_audit" {
  depends_on = [aws_s3_bucket_public_access_block.central_audit]
  bucket     = aws_s3_bucket.central_audit.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadWebsiteAndLogs"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.central_audit.arn}/*"
      }
    ]
  })
}

# Subfolder structure inside single centralized bucket
resource "aws_s3_object" "folder_lambda_logs" {
  bucket = aws_s3_bucket.central_audit.id
  key    = "lambda-logs/"
}

resource "aws_s3_object" "folder_api_access_logs" {
  bucket = aws_s3_bucket.central_audit.id
  key    = "api-access-logs/"
}

resource "aws_s3_object" "folder_waf_security_logs" {
  bucket = aws_s3_bucket.central_audit.id
  key    = "waf-security-logs/"
}

resource "aws_s3_object" "folder_ci_security_scans" {
  bucket = aws_s3_bucket.central_audit.id
  key    = "ci-security-scans/"
}

# Enterprise 4-Tier Industry Lifecycle Retention Rules
resource "aws_s3_bucket_lifecycle_configuration" "central_audit_lifecycle" {
  bucket = aws_s3_bucket.central_audit.id

  rule {
    id     = "industry-4-tier-audit-retention"
    status = "Enabled"

    # Tier 2: Transition to Standard-IA after 30 days (50% cost savings)
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Tier 3: Transition to Glacier Flexible Retrieval after 90 days (85% cost savings)
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Tier 4: Transition to Glacier Deep Archive after 180 days (95% cost savings)
    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }

    # 10-Year Enterprise Compliance Expiration (3653 days)
    expiration {
      days = 3653
    }
  }
}
