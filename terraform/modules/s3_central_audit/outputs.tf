output "bucket_name" {
  description = "Name of the single centralized audit & storage bucket"
  value       = aws_s3_bucket.central_audit.id
}

output "website_endpoint" {
  description = "Public URL for S3 static website hosting"
  value       = aws_s3_bucket_website_configuration.central_audit.website_endpoint
}

output "audit_folders" {
  description = "Configured audit log subfolders"
  value = [
    "lambda-logs/",
    "api-access-logs/",
    "waf-security-logs/",
    "ci-security-scans/"
  ]
}
