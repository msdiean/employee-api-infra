variable "aws_region" {
  description = "AWS region for the dev environment."
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment identifier."
  type        = string
  default     = "dev"
}

variable "lambda_package_path" {
  description = "Local path to the Lambda ZIP package."
  type        = string
  default     = "../../employee-api.zip"
}

variable "tags" {
  description = "Default tags to apply to resources."
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "employee-api"
  }
}
