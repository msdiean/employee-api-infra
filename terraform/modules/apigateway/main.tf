resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "REST API for employee management."
  tags        = var.tags
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

resource "aws_api_gateway_method" "post_employees" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.employees.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_employees" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.employees.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "get_employee" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.employee_item.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "put_employee" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.employee_item.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "delete_employee" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.employee_item.id
  http_method   = "DELETE"
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

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.this.id}/*/*/*"
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
}

data "aws_caller_identity" "current" {}
