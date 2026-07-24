# employee-api-infra Terraform

This directory defines reusable Terraform modules and a `dev` environment for deploying the Employee API infrastructure.

## Architecture

- Lambda function for the employee API
- API Gateway REST API fronting Lambda
- DynamoDB table named `employeeId` primary key
- IAM role granting Lambda least-privilege access to DynamoDB and CloudWatch Logs
- CloudWatch Log Group with 14-day retention

## Project Layout

- `modules/` - reusable modules for Lambda, DynamoDB, IAM, API Gateway, CloudWatch
- `environments/dev/` - dev environment using the reusable modules
- `scripts/package-lambda.ps1` - packaging script for the Lambda zip

## Usage

1. Build the Lambda deployment package from the sibling application project:

```powershell
Set-Location .\terraform\scripts
./package-lambda.ps1
```

This writes the ZIP to `terraform/employee-api.zip` by default, which is the path configured in the dev Terraform variables.

2. Change to the `terraform/environments/dev` directory.
3. Run:

```powershell
terraform init
terraform plan
terraform apply
```

For CI/CD, run the packaging step before `terraform apply` so the ZIP exists at the configured path.

## Notes

- The Lambda deployment package path is configured in `terraform.tfvars`.
- API Gateway uses Lambda proxy integration.
- The DynamoDB table is deployed with PAY_PER_REQUEST billing and PITR enabled.
