variable "vpc_name" {
  type        = string
  description = "Name tag prefix for VPC resources"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "private_subnet_1_cidr" {
  type        = string
  description = "CIDR block for Private Subnet 1"
  default     = "10.0.1.0/24"
}

variable "private_subnet_2_cidr" {
  type        = string
  description = "CIDR block for Private Subnet 2"
  default     = "10.0.2.0/24"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "tags" {
  type        = map(string)
  description = "Tags to assign to resources"
  default     = {}
}
