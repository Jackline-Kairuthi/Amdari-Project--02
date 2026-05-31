# Output the rds endpoint and secret ARNs for use in other modules
output "rds_endpoint" {
  value = aws_rds_cluster.sentinel.endpoint
}

output "redis_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "rds_secret_arn" {
  value = aws_secretsmanager_secret.rds.arn
}

output "redis_secret_arn" {
  value = aws_secretsmanager_secret.redis.arn
}

