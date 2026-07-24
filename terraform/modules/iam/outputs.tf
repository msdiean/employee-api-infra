output "role_name" {
  description = "Name of the IAM role."
  value       = aws_iam_role.lambda_role.name
}

output "role_arn" {
  description = "ARN of the IAM role."
  value       = aws_iam_role.lambda_role.arn
}
