# employee-api-infra

This repository contains the Terraform infrastructure for the Employee API.

## Lambda packaging for CI/CD

Before running Terraform, build the Lambda deployment ZIP:

```powershell
Set-Location .\terraform\scripts
./package-lambda.ps1
```

The script writes the artifact to:

- [terraform/employee-api.zip](terraform/employee-api.zip)

Terraform reads that file from [terraform/environments/dev/terraform.tfvars](terraform/environments/dev/terraform.tfvars).

## Deployment flow

1. Build the ZIP
2. Run Terraform plan/apply

For GitHub Actions, run the packaging step before `terraform apply`.
