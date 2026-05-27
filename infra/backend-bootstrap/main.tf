
########################################
# s3_backend_setup.tf
########################################

# Create S3 bucket for Terraform state
resource "aws_s3_bucket" "tf_state" {
  bucket = "sentinelpay-tf-state"   # must be globally unique

  tags = {
    Name        = "SentinelPay Terraform State"
    Environment = "dev"
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
