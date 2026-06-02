resource "aws_dynamodb_table" "terraform_locks" {
  name         = "sentinelpay-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
  enabled = true
}
  server_side_encryption {
  enabled     = true
  kms_key_arn = aws_kms_key.secrets.arn # Use the KMS key created for secrets encryption
}

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "Dev"
  }
}



