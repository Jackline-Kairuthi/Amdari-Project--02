###############################################
# APP DATA KMS KEY (WITH POLICY)
###############################################
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "s3_data_kms" {
  description         = "KMS key for SentinelPay application data"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowECSTasksToUseKey"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_role.payments_task_role.arn,
            aws_iam_role.kyc_task_role.arn
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowS3ToUseKey"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = [
              aws_s3_bucket.kyc_docs.arn,
              aws_s3_bucket.exports.arn
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name        = "SentinelPay S3 Data KMS Key"
    Environment = "dev"
  }
}

###############################################
# S3 BUCKETS FOR APP DATA (KYC + EXPORTS)
###############################################
resource "aws_s3_bucket" "kyc_docs" {
  bucket = "sentinelpay-kyc-docs"

  tags = {
    Name        = "SentinelPay KYC Docs"
    Environment = "dev"
  }
}

resource "aws_s3_bucket" "exports" {
  bucket = "sentinelpay-exports"

  tags = {
    Name        = "SentinelPay Exports"
    Environment = "dev"
  }
}

###############################################
# SSE-KMS ENCRYPTION
###############################################
resource "aws_s3_bucket_server_side_encryption_configuration" "kyc_docs" {
  bucket = aws_s3_bucket.kyc_docs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_data_kms.arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "exports" {
  bucket = aws_s3_bucket.exports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_data_kms.arn
    }
  }
}

###############################################
# BLOCK PUBLIC ACCESS
###############################################
resource "aws_s3_bucket_public_access_block" "kyc_docs" {
  bucket                  = aws_s3_bucket.kyc_docs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "exports" {
  bucket                  = aws_s3_bucket.exports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###############################################
# BUCKET POLICIES
###############################################
resource "aws_s3_bucket_policy" "kyc_docs_policy" {
  bucket = aws_s3_bucket.kyc_docs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTasksAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_role.payments_task_role.arn,
            aws_iam_role.kyc_task_role.arn
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.kyc_docs.arn,
          "${aws_s3_bucket.kyc_docs.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "exports_policy" {
  bucket = aws_s3_bucket.exports.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTasksAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            aws_iam_role.payments_task_role.arn,
            aws_iam_role.kyc_task_role.arn
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.exports.arn,
          "${aws_s3_bucket.exports.arn}/*"
        ]
      }
    ]
  })
}
