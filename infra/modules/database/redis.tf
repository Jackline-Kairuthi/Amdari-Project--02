## Redis subnet group for SentinelPay (connects Redis to private subnets)
resource "aws_elasticache_subnet_group" "redis" {
  name       = "sentinelpay-redis-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "sentinelpay-redis-subnet-group"
  }
}

## KMS KEY for ElastiCache Redis encryption
resource "aws_kms_key" "redis" {
  description             = "KMS key for ElastiCache"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "redis_alias" {
  name          = "alias/sentinelpay-redis-kms"
  target_key_id = aws_kms_key.redis.key_id
}

## Redis replication group (Redis 7, encrypted, private, secure)
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "sentinelpay-redis"
  description                   = "Redis cluster for SentinelPay"

  engine                        = "redis"
  engine_version                = "7.1"
  node_type                     = "cache.t3.micro"
  num_cache_clusters            = 1
  automatic_failover_enabled    = false
  multi_az_enabled              = false

  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  kms_key_id                    = aws_kms_key.redis.arn

  auth_token                    = random_password.redis_auth.result

  subnet_group_name             = aws_elasticache_subnet_group.redis.name
  security_group_ids            = [aws_security_group.redis_sg.id]

  tags = {
    Name = "sentinelpay-redis"
  }
}
