resource "aws_sns_topic" "security_alerts" {
  name = "security-alerts"

  # Fix: Enable KMS encryption
  kms_master_key_id = aws_kms_key.sns.arn
}

# Add your real email here
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = "you@example.com"
}