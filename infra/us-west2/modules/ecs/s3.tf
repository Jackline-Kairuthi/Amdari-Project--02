
########################################
# s3_backend_setup.tf
########################################

# Create S3 bucket for Terraform state
resource "aws_s3_bucket" "tf_state" {
  bucket = "sentinelpay-tf-state-west2"

  tags = {
    Name        = "SentinelPay Terraform State"
    Environment = "dev"
  }
}

# Create KMS key for encrypting Terraform state in S3
resource "aws_kms_key" "tf_state" {
  description = "KMS key for encrypting Terraform state in S3"

  tags = {
    Name        = "SentinelPay TF State KMS Key"
    Environment = "dev"
  }
}

# Configure server-side encryption for the S3 bucket using the KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.tf_state.arn
    }
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "tf_state_block" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}