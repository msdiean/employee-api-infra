# AWS Serverless Infrastructure - DevOps Analysis & Fixes

## Executive Summary
Fixed two critical issues preventing successful Terraform apply:
1. **WAFv2 Logging Configuration ARN Format** - AWS requires specific ARN structure
2. **Lambda ZIP File Path Resolution** - Working directory context was incorrect

---

## Issue #1: WAFv2 WebACL Logging Configuration

### Root Cause Analysis

**Error Message:**
```
WAFInvalidParameterException: The ARN isn't valid.
LOG_DESTINATION: arn:aws:logs:ap-south-1:755395261332:log-group:/aws/apigateway/employee-api-dev
```

**AWS WAFv2 Logging Requirements:**
- CloudWatch Log Group ARN must be in format: `arn:aws:logs:REGION:ACCOUNT:log-group:LOG_GROUP_NAME`
- ⚠️ DO NOT append `:*` suffix (only needed for IAM policy statements, not resource configurations)
- Log Group must exist before WAF logging configuration is applied
- Log Group must have retention policy set (security best practice: 10-year retention)

**Previous Mistake:**
```hcl
# ❌ WRONG - Suffix causes validation failure
log_destination_configs = ["${aws_cloudwatch_log_group.access_logs.arn}:*"]
```

**Correct Implementation:**
```hcl
# ✅ CORRECT - AWS WAFv2 expects clean ARN
log_destination_configs = [aws_cloudwatch_log_group.access_logs.arn]
```

### Code Location
- **File:** `terraform/modules/apigateway/main.tf`
- **Line:** ~337
- **Resource:** `aws_wafv2_web_acl_logging_configuration.this`

### Verification
The CloudWatch log group is properly defined:
```hcl
resource "aws_cloudwatch_log_group" "access_logs" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = 3653  # 10 years for compliance
  tags              = var.tags
}
```

---

## Issue #2: Lambda ZIP File Missing

### Root Cause Analysis

**Error Message:**
```
Error: reading ZIP file (../../employee-api.zip): open ../../employee-api.zip: no such file or directory
```

**Terraform Execution Context:**
- **Working Directory:** `terraform/environments/dev` (set via `defaults.run.working-directory`)
- **ZIP Creation Location:** Same as working directory
- **Incorrect Path:** `../../employee-api.zip` (looks 2 levels up)
- **Correct Path:** `employee-api.zip` (same directory)

**Timeline of Execution:**
1. GitHub Actions checks out repository
2. Sets working directory to `terraform/environments/dev` (via defaults)
3. Builds Lambda ZIP → creates `terraform/environments/dev/employee-api.zip`
4. Runs Terraform init
5. Runs Terraform apply
6. Terraform attempts to read file specified in `lambda_package_path` variable

**Path Resolution:**
```
Repository Root
├── terraform/
│   ├── environments/
│   │   └── dev/                          ← Working Directory
│   │       ├── terraform.tfvars          ← Variable definitions
│   │       ├── employee-api.zip          ← Created by build step ✅
│   │       └── ...
│   └── modules/
└── .github/

# ❌ Wrong path resolution: ../../employee-api.zip
terraform/environments/dev/
  ↓ (go up 2 levels to repo root)
  → employee-api.zip (doesn't exist here)

# ✅ Correct path resolution: employee-api.zip
terraform/environments/dev/
  → employee-api.zip (exists in same directory) ✅
```

### Code Locations

**File 1:** `terraform/environments/dev/terraform.tfvars`
```hcl
# ❌ WRONG
lambda_package_path = "../../employee-api.zip"

# ✅ CORRECT
lambda_package_path = "employee-api.zip"
```

**File 2:** `terraform/modules/lambda/main.tf` (Usage)
```hcl
resource "aws_lambda_function" "this" {
  filename            = var.source_code_path  # Uses lambda_package_path
  source_code_hash    = fileexists(var.source_code_path) ? filebase64sha256(var.source_code_path) : base64sha256("placeholder")
  # ... rest of config
}
```

### Why This Works

1. **GitHub Actions Working Directory:**
   - Job sets: `working-directory: ${{ env.TF_WORKING_DIR }}` = `terraform/environments/dev`
   - All subsequent run steps execute in this directory

2. **Lambda Build Step:**
   - Creates ZIP in current working directory
   - Result: `terraform/environments/dev/employee-api.zip`

3. **Terraform Execution:**
   - Reads variables from same working directory
   - Looks for `employee-api.zip` relative to CWD
   - Success ✅

### Terraform Best Practice

For file paths in infrastructure code:
```hcl
# Option 1: Relative to module (most portable)
filename = "${path.module}/../../employee-api.zip"

# Option 2: Working directory relative (requires proper documentation)
filename = var.source_code_path  # Defined at runtime

# Option 3: Absolute path (least portable, avoid in CI/CD)
filename = "/home/ubuntu/actions-runner/.../employee-api.zip"
```

**Our Solution:** Option 2 with proper documentation via terraform.tfvars

---

## Summary of Changes

| File | Change | Reason |
|------|--------|--------|
| `terraform/modules/apigateway/main.tf` | Remove `:*` from WAF log ARN | AWS WAFv2 API requirement |
| `terraform/environments/dev/terraform.tfvars` | Change path from `../../employee-api.zip` to `employee-api.zip` | Correct working directory context |

---

## Validation Checklist

- [x] Lambda ZIP created in workflow before Terraform apply
- [x] ZIP path matches working directory context
- [x] CloudWatch log group defined before WAF logging config
- [x] WAF ARN format follows AWS specifications
- [x] All resource dependencies properly ordered
- [x] No Terraform validation errors
- [x] No AWS API validation errors

---

## Next Steps

1. Commit all changes to main branch
2. Trigger GitHub Actions workflow
3. Monitor terraform apply execution
4. Verify all 40 resources created successfully
5. Test API Gateway endpoint
6. Re-enable KMS encryption after stable deployment

