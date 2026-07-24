output "api_gateway_url" {
  description = "Invoke URL for the API Gateway deployment."
  value       = module.apigateway.invoke_url
}

output "lambda_arn" {
  description = "ARN of the deployed Lambda function."
  value       = module.lambda.lambda_function_arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB employees table."
  value       = module.dynamodb.table_name
}
