terraform {
  required_version = ">= 1.12"

  backend "s3" {
    bucket         = "coz-serverless"
    key            = "employee-api-infra/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
