variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for frontend website hosting"
}

variable "tags" {
  type        = map(string)
  description = "Tags for resources"
  default     = {}
}
