variable "api_name" {
  description = "Name of the API Gateway REST API."
  type        = string
}

variable "lambda_arn" {
  description = "ARN of the Lambda function to integrate."
  type        = string
}

variable "aws_region" {
  description = "AWS region used to build API Gateway Lambda integration URI."
  type        = string
}

variable "stage_name" {
  description = "Deployment stage name for API Gateway."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags to apply to API Gateway resources."
  type        = map(string)
  default     = {}
}
