resource "aws_sns_topic" "security_alerts" {
  name = "security-alerts"
}

# Add your real email here
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = "you@example.com"
}