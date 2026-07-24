variable "log_group_name" {
  description = "Name of the CloudWatch Log Group."
  type        = string
}

variable "retention_in_days" {
  description = "Retention period for log events in days."
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags applied to CloudWatch resources."
  type        = map(string)
  default     = {}
}
