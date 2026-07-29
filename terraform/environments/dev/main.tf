locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
  })

  lambda_name         = "employee-api-${var.environment}"
  dynamodb_table_name = "employee-api-employees-${var.environment}"
  log_group_name      = "/aws/lambda/${local.lambda_name}"
  api_name            = "employee-api-${var.environment}"
}

module "dynamodb" {
  source     = "../../modules/dynamodb"
  table_name = local.dynamodb_table_name
  tags       = local.common_tags
}

module "cloudwatch" {
  source            = "../../modules/cloudwatch"
  log_group_name    = local.log_group_name
  retention_in_days = 3653
  tags              = local.common_tags
}

module "iam" {
  source             = "../../modules/iam"
  role_name          = "employee-api-lambda-${var.environment}"
  dynamodb_table_arn = module.dynamodb.table_arn
  log_group_name     = local.log_group_name
  aws_region         = var.aws_region
  tags               = local.common_tags
}

module "vpc" {
  source     = "../../modules/vpc"
  vpc_name   = "employee-api-vpc-${var.environment}"
  aws_region = var.aws_region
  tags       = local.common_tags
}

# AWS Secrets Manager Secret for Datadog API Key
resource "aws_secretsmanager_secret" "datadog_api_key" {
  count       = var.datadog_api_key != "" ? 1 : 0
  name        = "employee-api-${var.environment}-datadog-api-key"
  description = "Datadog API Key for telemetry and trace collection"
  tags        = local.common_tags
}

resource "aws_secretsmanager_secret_version" "datadog_api_key_val" {
  count         = var.datadog_api_key != "" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.datadog_api_key[0].id
  secret_string = var.datadog_api_key
}

# IAM Policy to allow Lambda to read Datadog API Key secret
resource "aws_iam_role_policy" "lambda_secrets_access" {
  count = var.datadog_api_key != "" ? 1 : 0
  name  = "employee-api-${var.environment}-secrets-policy"
  role  = module.iam.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["secretsmanager:GetSecretValue"]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.datadog_api_key[0].arn
      }
    ]
  })
}

module "lambda" {
  source                     = "../../modules/lambda"
  function_name              = local.lambda_name
  runtime                    = "nodejs22.x"
  handler                    = "src/index.handler"
  memory_size                = 512
  timeout                    = 10
  source_code_path           = var.lambda_package_path
  role_arn                   = module.iam.role_arn
  subnet_ids                 = module.vpc.private_subnet_ids
  security_group_ids         = [module.vpc.lambda_security_group_id]
  datadog_api_key_secret_arn = length(aws_secretsmanager_secret.datadog_api_key) > 0 ? aws_secretsmanager_secret.datadog_api_key[0].arn : ""
  environment_variables = {
    TABLE_NAME = module.dynamodb.table_name
    APP_REGION = var.aws_region
  }
  tags = local.common_tags
}

module "apigateway" {
  source     = "../../modules/apigateway"
  api_name   = local.api_name
  lambda_arn = module.lambda.lambda_alias_arn
  aws_region = var.aws_region
  stage_name = var.environment
  tags       = local.common_tags
}

data "aws_caller_identity" "current" {}

module "s3_central_audit" {
  source      = "../../modules/s3_central_audit"
  bucket_name = "employee-api-central-audit-${var.environment}-${data.aws_caller_identity.current.account_id}"
  tags        = local.common_tags
}
