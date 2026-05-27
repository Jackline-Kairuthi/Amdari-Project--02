# Create DynamoDB table for state locking
resource "aws_dynamodb_table" "tf_lock" {
  name         = "sentinelpay-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "sentinelpay Lock Table"
    Environment = "Dev"
  }
}