resource "aws_cloudwatch_log_group" "payments_api" {
  name              = "/ecs/payments-api"
  retention_in_days = 365

  # Fix: Encrypt with KMS CMK
  kms_key_id = aws_kms_key.logs.arn
}

resource "aws_cloudwatch_log_group" "kyc_api" {
  name              = "/ecs/kyc-api"
  retention_in_days = 365

  # Fix: Encrypt with KMS CMK
  kms_key_id = aws_kms_key.logs.arn
}
