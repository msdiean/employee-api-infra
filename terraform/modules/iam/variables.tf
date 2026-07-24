variable "role_name" {
  description = "Name of the IAM role for Lambda."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table Lambda will access."
  type        = string
}

variable "log_group_name" {
  description = "Name of the CloudWatch Log Group for Lambda."
  type        = string
}

variable "aws_region" {
  description = "AWS region for resource ARNs."
  type        = string
}

variable "tags" {
  description = "Tags to assign to IAM resources."
  type        = map(string)
  default     = {}
}
