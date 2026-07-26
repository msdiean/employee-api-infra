variable "bucket_name" {
  type        = string
  description = "Name of the centralized audit and storage S3 bucket"
}

variable "tags" {
  type        = map(string)
  description = "Tags for resources"
  default     = {}
}
