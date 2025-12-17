package system

################################
# Default
################################
default allow = false

################################
# Allow if no violations
################################
allow {
  count(violations) == 0
}

################################
# Main output
################################
main = {
  "allow": allow,
  "violations": violations
}

################################
# Collect violations
################################
violations[msg] {
  ec2_violation[msg]
}

violations[msg] {
  s3_violation[msg]
}

################################
# EC2 Instance Type Policy
################################
ec2_violation[msg] {
  name := resource_name
  res := input.Resources[resource_name]

  res.Type == "AWS::EC2::Instance"

  allowed := ["t2.micro", "t2.small", "t3.micro", "t3.small"]
  itype := res.Properties.InstanceType

  not allowed_contains(allowed, itype)

  msg := sprintf(
    "EC2 instance '%s' uses disallowed instance type '%s'. Allowed: %v",
    [name, itype, allowed]
  )
}

allowed_contains(list, value) {
  list[i]
  list[i] == value
}

################################
# S3 Public Access Block Policy
################################
s3_violation[msg] {
  bucket_name := resource_name
  bucket := input.Resources[resource_name]

  bucket.Type == "AWS::S3::Bucket"

  not s3_public_access_blocked

  msg := sprintf(
    "S3 bucket '%s' must have public access blocked",
    [bucket_name]
  )
}

################################
# Helpers (SAFE, NO `_`)
################################

# Case 1: Inline Serverless config
s3_public_access_blocked {
  some name
  bucket := input.Resources[name]
  bucket.Type == "AWS::S3::Bucket"

  pab := bucket.Properties.PublicAccessBlockConfiguration
  pab.BlockPublicAcls == true
  pab.BlockPublicPolicy == true
  pab.IgnorePublicAcls == true
  pab.RestrictPublicBuckets == true
}

# Case 2: Explicit CloudFormation resource
s3_public_access_blocked {
  some name
  pab := input.Resources[name]
  pab.Type == "AWS::S3::BucketPublicAccessBlock"
}
