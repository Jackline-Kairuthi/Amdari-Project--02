###############################################
# KMS Key for Secrets Manager
###############################################
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "secrets" {
  description             = "KMS key for encrypting Secrets Manager secrets (RDS, Redis)"
  deletion_window_in_days = 7
  enable_key_rotation     = true

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




