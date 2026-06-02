# checkov:skip=CKV_AWS_273:This IAM user is a honeytoken and intentionally violates SSO policy
resource "aws_iam_user" "honeytoken" {
  name = "prod-admin-backup"
  tags = {
    Purpose = "HONEYTOKEN_DO_NOT_USE"
  }
}

# checkov:skip=CKV_AWS_40:Honeytoken requires an access key
# checkov:skip=CKV_AWS_41:Honeytoken access key is intentionally static
resource "aws_iam_access_key" "honeytoken" {
  user = aws_iam_user.honeytoken.name
}

output "honeytoken_access_key_id" {
  value       = aws_iam_access_key.honeytoken.id
  description = "Store this somewhere tempting; alert on any use."
}
