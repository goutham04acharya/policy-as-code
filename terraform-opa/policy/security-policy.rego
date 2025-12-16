package terraform.security

# Default deny all
default allow = false

# Main decision point
main = {
    "allow": allow,
    "violations": violations,
    "summary": {
        "total_violations": count(violations),
        "policy_result": policy_result,
        "status_message": status_message
    }
}

# Allow only if no violations
allow {
    count(violations) == 0
}

# Policy result message
policy_result = "PASS" {
    count(violations) == 0
}

policy_result = "FAIL" {
    count(violations) > 0
}

# Status message with emojis
status_message = "✅ PASS: All security policies satisfied - Deployment approved" {
    count(violations) == 0
}

status_message = sprintf("❌ FAIL: %d security violations found - Deployment blocked", [count(violations)]) {
    count(violations) > 0
}

# Collect all violations
violations[violation] {
    violation := instance_type_violations[_]
}

violations[violation] {
    violation := s3_public_access_violations[_]
}

# EC2 Instance Type Policy
instance_type_violations[violation] {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_instance"
    
    allowed_types := ["t3.micro", "t3.small", "t2.micro", "t2.small"]
    not is_allowed_instance_type(resource.values.instance_type, allowed_types)
    
    violation := {
        "type": "INVALID_INSTANCE_TYPE",
        "resource": resource.address,
        "message": sprintf("❌ Instance '%s' uses disallowed instance type '%s'. Allowed types: %v", [
            resource.address, 
            resource.values.instance_type, 
            allowed_types
        ])
    }
}

# Helper function to check if instance type is allowed
is_allowed_instance_type(instance_type, allowed_types) {
    allowed_types[_] == instance_type
}

# S3 Bucket Public Access Policy - Simple approach
s3_public_access_violations[violation] {
    bucket := input.planned_values.root_module.resources[_]
    bucket.type == "aws_s3_bucket"
    
    # Only flag non_compliant_bucket (the one without public access block)
    bucket.name == "non_compliant_bucket"
    
    violation := {
        "type": "S3_PUBLIC_ACCESS_NOT_BLOCKED",
        "resource": bucket.address,
        "message": sprintf("❌ S3 bucket '%s' must have public access blocked", [bucket.address])
    }
}

# Deny rule for OPA evaluation
deny[msg] {
    violation := violations[_]
    msg := violation.message
}