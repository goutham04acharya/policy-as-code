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

## SBOM

### How to Run

1. **Navigate to SBOM Directory**
   ```bash
   cd sbom-opa
   ```

2. **Configure Scenario**
   - For **PASS**: `cp package-pass.json package.json`
   - For **FAIL**: `cp package-vulnerable.json package.json`

3. **Execute Policy Validation**
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   npx @cyclonedx/cyclonedx-npm --output-file reports/sbom/sbom.json --output-format JSON --spec-version 1.6
   grype sbom:reports/sbom/sbom.json --add-cpes-if-none -o json > reports/sbom/vulnerability-report.json
   opa exec --decision sbom/security/result --bundle policy/ reports/sbom/vulnerability-report.json
   ```

### Expected Results
- **PASS**: `✅ APPROVED - SBOM Security Policy: APPROVED` (0 vulnerabilities)
- **FAIL**: `❌ REJECTED - SBOM Security Policy: REJECTED` with critical/high vulnerabilities listed

### Policies Enforced
- Critical vulnerabilities: Deployment blocked
- High vulnerabilities: Deployment blocked
- Medium/Low vulnerabilities: Deployment allowed

## Prerequisites

### For Terraform
- Terraform CLI
- OPA CLI
- AWS CLI (configured)

### For CloudFormation
- Node.js and npm
- Serverless Framework
- OPA CLI

### For SBOM
- Node.js and npm
- CycloneDX npm plugin: `npm install -g @cyclonedx/cyclonedx-npm`
- Grype vulnerability scanner: [Installation Guide](https://github.com/anchore/grype#installation)
- OPA CLI

## Repository Structure

```
policy-as-code/
├── terraform-opa/
│   ├── terraform/
│   │   └── main.tf                 # Terraform resources (PASS/FAIL scenarios)
│   ├── policy/
│   │   └── security-policy.rego    # OPA security policies
│   └── plans/                      # Generated Terraform plans
├── cloudformation-opa/
│   ├── services/demo-service/
│   │   └── serverless.yml          # CloudFormation template
│   └── policy/
│       ├── serverless-governance.rego
│       └── validate-governance.sh
└── sbom-opa/
    ├── policy/
    │   └── sbom-security.rego      # SBOM vulnerability policies
    ├── reports/sbom/               # Generated SBOM and scan results
    ├── package-pass.json           # Secure dependencies (PASS)
    ├── package-vulnerable.json     # Vulnerable dependencies (FAIL)
    └── package.json                # Current dependencies
```

## CI/CD Integration

Each implementation can be integrated into CI/CD pipelines:

1. **Build Stage**: Generate plans/templates/SBOMs
2. **Security Stage**: Scan for policy violations
3. **Policy Stage**: Evaluate against OPA policies
4. **Decision**: Block deployment if violations found

## Installation Commands

If tools are missing, install them:

```bash
# OPA
curl -L -o opa https://openpolicyagent.org/downloads/v0.58.0/opa_linux_amd64_static
chmod 755 ./opa
sudo mv opa /usr/local/bin

# Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Grype
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# CycloneDX
npm install -g @cyclonedx/cyclonedx-npm

# Serverless Framework
npm install -g serverless
```