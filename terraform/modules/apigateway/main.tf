resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "REST API for employee management."
  tags        = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_resource" "employees" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "employees"
}

resource "aws_api_gateway_resource" "employee_item" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.employees.id
  path_part   = "{employeeId}"
}

resource "aws_api_gateway_request_validator" "this" {
  rest_api_id                 = aws_api_gateway_rest_api.this.id
  name                        = "${var.api_name}-request-validator"
  validate_request_parameters = true
  validate_request_body       = true
}

resource "aws_api_gateway_client_certificate" "this" {
  description = "Client certificate for API Gateway stage"
}

resource "aws_api_gateway_method" "post_employees" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.employees.id
  http_method          = "POST"
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.this.id
}

resource "aws_api_gateway_method" "get_employees" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.employees.id
  http_method          = "GET"
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.this.id
}

resource "aws_api_gateway_method" "get_employee" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.employee_item.id
  http_method          = "GET"
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.this.id
}

resource "aws_api_gateway_method" "put_employee" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.employee_item.id
  http_method          = "PUT"
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.this.id
}

resource "aws_api_gateway_method" "delete_employee" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.employee_item.id
  http_method          = "DELETE"
  authorization        = "AWS_IAM"
  request_validator_id = aws_api_gateway_request_validator.this.id
}

locals {
  lambda_uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_arn}/invocations"
}

resource "aws_api_gateway_integration" "post_employees" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.employees.id
  http_method             = aws_api_gateway_method.post_employees.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.lambda_uri
}

resource "aws_api_gateway_integration" "get_employees" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.employees.id
  http_method             = aws_api_gateway_method.get_employees.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.lambda_uri
}

resource "aws_api_gateway_integration" "get_employee" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.employee_item.id
  http_method             = aws_api_gateway_method.get_employee.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.lambda_uri
}

resource "aws_api_gateway_integration" "put_employee" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.employee_item.id
  http_method             = aws_api_gateway_method.put_employee.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.lambda_uri
}

resource "aws_api_gateway_integration" "delete_employee" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.employee_item.id
  http_method             = aws_api_gateway_method.delete_employee.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.lambda_uri
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/*/*"
}

resource "aws_kms_key" "access_logs_encryption" {
  description             = "KMS key for API Gateway access logs"
  enable_key_rotation     = true
  deletion_window_in_days = 10
  tags                    = var.tags
}

resource "aws_kms_alias" "access_logs_encryption" {
  name          = "alias/${replace(replace(replace(var.api_name, "/", ""), "-", ""), "_", "")}-access-logs"
  target_key_id = aws_kms_key.access_logs_encryption.key_id
}

resource "aws_cloudwatch_log_group" "access_logs" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = 3653
  kms_key_id        = aws_kms_key.access_logs_encryption.arn
  tags              = var.tags
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha256(jsonencode([
      aws_api_gateway_resource.employees.id,
      aws_api_gateway_resource.employee_item.id,
      aws_api_gateway_method.post_employees.id,
      aws_api_gateway_method.get_employees.id,
      aws_api_gateway_method.get_employee.id,
      aws_api_gateway_method.put_employee.id,
      aws_api_gateway_method.delete_employee.id,
      aws_api_gateway_integration.post_employees.id,
      aws_api_gateway_integration.get_employees.id,
      aws_api_gateway_integration.get_employee.id,
      aws_api_gateway_integration.put_employee.id,
      aws_api_gateway_integration.delete_employee.id,
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.post_employees,
    aws_api_gateway_integration.get_employees,
    aws_api_gateway_integration.get_employee,
    aws_api_gateway_integration.put_employee,
    aws_api_gateway_integration.delete_employee,
    aws_lambda_permission.api_gateway,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name
  deployment_id = aws_api_gateway_deployment.this.id
  description   = "${var.stage_name} deployment stage"
  tags          = var.tags

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access_logs.arn
    format          = "$context.requestId"
  }

  xray_tracing_enabled  = true
  cache_cluster_enabled = true
  cache_cluster_size    = "0.5"
  client_certificate_id = aws_api_gateway_client_certificate.this.id

  method_settings {
    metrics_enabled        = true
    logging_level          = "INFO"
    data_trace_enabled     = true
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
    caching_enabled        = true
    cache_ttl_in_seconds   = 300
    cache_data_encrypted   = true
  }
}

resource "aws_wafv2_web_acl" "this" {
  name  = "${var.api_name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "${replace(var.api_name, "-", "")}-waf"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_api_gateway_stage.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}

data "aws_caller_identity" "current" {}
