# -----------------------------
# RDS admin credentials secret
# -----------------------------
resource "random_password" "rds" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret" "rds" {
  name = "sentinelpay/rds/admin"

#Fix encrypted secret string with KMS key
kms_key_id = aws_kms_key.secrets.arn
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id     = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = "sentinelpayadmin"
    password = random_password.rds.result
  })
}

# -----------------------------
# Redis AUTH token secret
# -----------------------------
resource "random_password" "redis_auth" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "redis" {
  name = "sentinelpay/redis/auth-token"

# Fix encrypted secret string with KMS key
kms_key_id = aws_kms_key.secrets.arn
}
resource "aws_secretsmanager_secret_version" "redis" {
  secret_id     = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({
    auth_token = random_password.redis_auth.result
  })
}


