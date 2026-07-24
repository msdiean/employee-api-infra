output "invoke_url" {
  description = "Base URL for the deployed API Gateway stage."
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}"
}
