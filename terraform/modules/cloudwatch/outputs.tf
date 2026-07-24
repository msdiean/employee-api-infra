output "log_group_name" {
  description = "Name of the CloudWatch Log Group created for Lambda."
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}
