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

resource "aws_api_gateway_method" "post_employees" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.employees.id
  http_method          = "POST"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.this.id
}

resource "aws_api_gateway_method" "get_employees" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.employees.id
  http_method          = "GET"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.this.id
}

resource "aws_api_gateway_method" "get_employee" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.employee_item.id
  http_method          = "GET"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.this.id
}

resource "aws_api_gateway_method" "put_employee" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.employee_item.id
  http_method          = "PUT"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.this.id
}

resource "aws_api_gateway_method" "delete_employee" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.employee_item.id
  http_method          = "DELETE"
  authorization        = "NONE"
  request_validator_id = aws_api_gateway_request_validator.this.id
}

resource "aws_api_gateway_method" "options_employees" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.employees.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options_employee_item" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.employee_item.id
  http_method   = "OPTIONS"
  authorization = "NONE"
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

resource "aws_api_gateway_integration" "options_employees" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.employees.id
  http_method             = aws_api_gateway_method.options_employees.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.lambda_uri
}

resource "aws_api_gateway_integration" "options_employee_item" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.employee_item.id
  http_method             = aws_api_gateway_method.options_employee_item.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = local.lambda_uri
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id_prefix = "AllowAPIGatewayInvoke-"
  action              = "lambda:InvokeFunction"
  function_name       = split(":", var.lambda_arn)[6]
  qualifier           = length(split(":", var.lambda_arn)) > 7 ? split(":", var.lambda_arn)[7] : null
  principal           = "apigateway.amazonaws.com"
  source_arn          = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/*/*"
}

data "aws_caller_identity" "current" {}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha256(jsonencode([
      local.lambda_uri,
      aws_api_gateway_resource.employees.id,
      aws_api_gateway_resource.employee_item.id,
      aws_api_gateway_method.post_employees.id,
      aws_api_gateway_method.get_employees.id,
      aws_api_gateway_method.get_employee.id,
      aws_api_gateway_method.put_employee.id,
      aws_api_gateway_method.delete_employee.id,
      aws_api_gateway_method.options_employees.id,
      aws_api_gateway_method.options_employee_item.id,
      aws_api_gateway_integration.post_employees.id,
      aws_api_gateway_integration.get_employees.id,
      aws_api_gateway_integration.get_employee.id,
      aws_api_gateway_integration.put_employee.id,
      aws_api_gateway_integration.delete_employee.id,
      aws_api_gateway_integration.options_employees.id,
      aws_api_gateway_integration.options_employee_item.id,
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.post_employees,
    aws_api_gateway_integration.get_employees,
    aws_api_gateway_integration.get_employee,
    aws_api_gateway_integration.put_employee,
    aws_api_gateway_integration.delete_employee,
    aws_api_gateway_integration.options_employees,
    aws_api_gateway_integration.options_employee_item,
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

  xray_tracing_enabled = true
}

resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    data_trace_enabled     = false
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
}

resource "aws_wafv2_web_acl" "this" {
  name  = "${var.api_name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitRule"
    priority = 0

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    action {
      block {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(var.api_name, "-", "")}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(var.api_name, "-", "")}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "Log4jProtectionRule"
    priority = 2

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${replace(var.api_name, "-", "")}-log4j-protection"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${replace(var.api_name, "-", "")}-waf"
    sampled_requests_enabled   = true
  }
}


resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = aws_api_gateway_stage.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
