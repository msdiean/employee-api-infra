output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function."
  value       = aws_lambda_function.this.invoke_arn
}

output "lambda_alias_arn" {
  description = "ARN of the Lambda live alias."
  value       = aws_lambda_alias.live.arn
}

output "lambda_alias_invoke_arn" {
  description = "Invoke ARN of the Lambda live alias."
  value       = aws_lambda_alias.live.invoke_arn
}

