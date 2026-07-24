Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$terraformDir = Join-Path $repoRoot "terraform/environments/dev"

Set-Location $terraformDir
Write-Host "Running terraform fmt check..."
terraform fmt -check -recursive
Write-Host "Running terraform init..."
terraform init -input=false
Write-Host "Running terraform validate..."
terraform validate
Write-Host "Terraform validation completed successfully."
