# policy-as-code
This repository provides a complete Policy-as-Code implementation using OPA, including Terraform plan validation, CloudFormation governance, and SBOM vulnerability enforcement with Grype. Designed for CI/CD automation, security, and cloud governance.

## TERRAFORM

### How to Run

1. **Initialize Terraform**
   ```bash
   cd terraform-opa/terraform
   terraform init
   ```

2. **Configure Scenario**
   - For **PASS**: Keep PASS SCENARIO uncommented, comment out FAIL SCENARIO in `main.tf`
   - For **FAIL**: Uncomment FAIL SCENARIO section in `main.tf`

3. **Execute Policy Validation**
   ```bash
   terraform plan -out=../plans/tfplan_large.binary
   terraform show -json ../plans/tfplan_large.binary > ../plans/tfplan_large.json
   opa eval --input ../plans/tfplan_large.json --data ../policy/security-policy.rego "data.terraform.security.main"
   ```

### Expected Results
- **PASS**: `✅ PASS: All security policies satisfied - Deployment approved`
- **FAIL**: `❌ FAIL: 2 security violations found - Deployment blocked`

### Policies Enforced
- EC2 instance types: Only `t3.micro`, `t3.small`, `t2.micro`, `t2.small` allowed
- S3 buckets: Must have public access blocked

## CLOUDFORMATION

### How to Run

1. **Navigate to Demo Service**
   ```bash
   cd cloudformation-opa/services/demo-service
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Configure Scenario**
   - For **PASS**: Keep default configuration in `serverless.yml`
   - For **FAIL**: Modify `serverless.yml`:
     - Change EC2 instance type to `m5.large`
     - Remove `PublicAccessBlockConfiguration` block from S3 bucket

4. **Execute Policy Validation**
   ```bash
   sls package
   ```

### Expected Results
- **PASS**: `✅ PASSED - Governance checks successful`
- **FAIL**: `❌ FAILED - Governance violations detected` with specific violations listed

### Policies Enforced
- EC2 instance types: Only `t2.micro`, `t2.small`, `t3.micro`, `t3.small` allowed
- S3 buckets: Must have public access blocked
