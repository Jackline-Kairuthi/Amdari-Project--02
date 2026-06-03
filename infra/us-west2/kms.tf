###############################################
# KMS KEY — SECRETS MANAGER (RDS + REDIS)
###############################################
resource "aws_kms_key" "secrets" {
  description         = "KMS key for encrypting Secrets Manager secrets (RDS, Redis)"
  deletion_window_in_days = 7
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
      }
    ]
  })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/sentinelpay-secrets-kms"
  target_key_id = aws_kms_key.secrets.key_id
}

###############################################
# KMS KEY — SNS SECURITY ALERTS
###############################################
resource "aws_kms_key" "sns" {
  description         = "KMS key for SNS security alerts"
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
      }
    ]
  })
}

resource "aws_kms_alias" "sns" {
  name          = "alias/sentinelpay-sns-kms"
  target_key_id = aws_kms_key.sns.key_id
}

###############################################
# KMS KEY — CLOUDTRAIL LOG ENCRYPTION
###############################################
resource "aws_kms_key" "cloudtrail" {
  description         = "KMS key for CloudTrail log file encryption"
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
      }
    ]
  })
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/sentinelpay-cloudtrail-kms"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

###############################################
# KMS KEY — CLOUDWATCH LOG GROUPS
###############################################
resource "aws_kms_key" "logs" {
  description         = "KMS key for CloudWatch log group encryption"
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
      }
    ]
  })
}

resource "aws_kms_alias" "logs" {
  name          = "alias/sentinelpay-logs-kms"
  target_key_id = aws_kms_key.logs.key_id
}

###############################################
# DATA SOURCE — ACCOUNT ID
###############################################
data "aws_caller_identity" "current" {}

