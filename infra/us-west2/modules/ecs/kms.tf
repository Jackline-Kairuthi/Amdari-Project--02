#################################################
#KMS KEY FOR LOGS
#################################################
resource "aws_kms_key" "logs" {
  description = "KMS key for ECS CloudWatch logs"
  deletion_window_in_days = 7
  enable_key_rotation = true
}

#################################################
# Alias for logs KMS key
#################################################
resource "aws_kms_alias" "logs_alias" {
  name          = "alias/ecs-cloudwatch-logs"
  target_key_id = aws_kms_key.logs.key_id
}
