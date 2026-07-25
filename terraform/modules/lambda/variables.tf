variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "runtime" {
  description = "Runtime for the Lambda function."
  type        = string
}

variable "handler" {
  description = "Entry point handler for Lambda."
  type        = string
}

variable "memory_size" {
  description = "Lambda function memory size in MB."
  type        = number
  default     = 512
}

variable "timeout" {
  description = "Lambda function timeout in seconds."
  type        = number
  default     = 10
}

variable "source_code_path" {
  description = "Local path to the Lambda deployment package zip."
  type        = string
}

variable "role_arn" {
  description = "IAM role ARN assumed by Lambda."
  type        = string
}

variable "environment_variables" {
  description = "Environment variables to pass to the Lambda function."
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "Subnet IDs for the Lambda VPC configuration."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for the Lambda VPC configuration."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to Lambda resources."
  type        = map(string)
  default     = {}
}
