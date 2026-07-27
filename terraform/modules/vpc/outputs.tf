output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The ID of the VPC"
}

output "private_subnet_ids" {
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  description = "List of IDs of private subnets"
}

output "lambda_security_group_id" {
  value       = aws_security_group.lambda_sg.id
  description = "Security group ID assigned to Lambda"
}

output "dynamodb_endpoint_id" {
  value       = aws_vpc_endpoint.dynamodb.id
  description = "The ID of the DynamoDB VPC Gateway Endpoint"
}
