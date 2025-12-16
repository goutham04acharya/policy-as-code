# Terraform configuration for OPA policy testing
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Random ID for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Data source for AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# =============================================================================
# PASS SCENARIO - COMPLIANT RESOURCES (Uncomment for PASS test)
# =============================================================================

# COMPLIANT: EC2 instance with allowed instance type (t3.micro)
resource "aws_instance" "compliant_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  tags = {
    Name        = "compliant-instance"
    Environment = "production"
  }
}

# COMPLIANT: S3 bucket with public access blocked
resource "aws_s3_bucket" "compliant_bucket" {
  bucket = "compliant-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Environment = "production"
    Purpose     = "compliant-demo"
  }
}

resource "aws_s3_bucket_public_access_block" "compliant_public_access_block" {
  bucket = aws_s3_bucket.compliant_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# FAIL SCENARIO - NON-COMPLIANT RESOURCES (Uncomment for FAIL test)
# =============================================================================

# NON-COMPLIANT: EC2 instance with disallowed instance type (m5.large)
# resource "aws_instance" "non_compliant_instance" {
#   ami           = data.aws_ami.amazon_linux.id
#   instance_type = "m5.large"
# 
#   tags = {
#     Name = "non-compliant-instance"
#   }
# }
# 
# # NON-COMPLIANT: S3 bucket without public access block
# resource "aws_s3_bucket" "non_compliant_bucket" {
#   bucket = "non-compliant-bucket-${random_id.bucket_suffix.hex}"
# 
#   tags = {
#     Environment = "development"
#   }
# }