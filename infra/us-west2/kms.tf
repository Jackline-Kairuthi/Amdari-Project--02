resource "aws_kms_key" "secrets" {
  description             = "KMS key for encrypting RDS secret"
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
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

