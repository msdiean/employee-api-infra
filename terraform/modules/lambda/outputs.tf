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

output "auto_rollback_function_name" {
  description = "Name of the Auto-Rollback handler Lambda function."
  value       = aws_lambda_function.auto_rollback.function_name
}

output "cloudwatch_alarm_name" {
  description = "Name of the CloudWatch error alarm."
  value       = aws_cloudwatch_metric_alarm.lambda_errors.alarm_name
}


