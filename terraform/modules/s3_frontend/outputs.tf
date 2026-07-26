output "bucket_name" {
  description = "Name of the frontend S3 bucket"
  value       = aws_s3_bucket.frontend.id
}

output "website_endpoint" {
  description = "Public URL for S3 static website hosting"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}
