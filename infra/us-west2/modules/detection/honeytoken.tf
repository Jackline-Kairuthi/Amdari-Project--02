resource "aws_iam_user" "honeytoken" {
  name = "prod-admin-backup"
  tags = {
    Purpose = "HONEYTOKEN_DO_NOT_USE"
  }
}

resource "aws_iam_access_key" "honeytoken" {
  user = aws_iam_user.honeytoken.name
}

output "honeytoken_access_key_id" {
  value       = aws_iam_access_key.honeytoken.id
  description = "Store this somewhere tempting; alert on any use."
}