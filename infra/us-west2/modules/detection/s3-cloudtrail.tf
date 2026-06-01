resource "aws_s3_bucket" "cloudtrail" {
  bucket = var.trail_bucket_name

  object_lock_enabled = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "cloudtrail-retention"
    enabled = true

    noncurrent_version_expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_object_lock_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.bucket

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}