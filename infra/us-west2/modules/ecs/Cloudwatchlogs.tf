resource "aws_cloudwatch_log_group" "payments_api" {
  name              = "/ecs/payments-api"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "kyc_api" {
  name              = "/ecs/kyc-api"
  retention_in_days = 30
}
