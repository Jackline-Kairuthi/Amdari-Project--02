###############################################
# ECS EXECUTION ROLE (pull image + write logs)
###############################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach AWS-managed execution policy
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

###############################################
# PAYMENTS TASK ROLE (app-level permissions)
###############################################
resource "aws_iam_role" "payments_task_role" {
  name = "paymentsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

###############################################
# KYC TASK ROLE (app-level permissions)
###############################################
resource "aws_iam_role" "kyc_task_role" {
  name = "kycTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

###############################################
# SECRET ACCESS POLICY (shared by both tasks)
###############################################
resource "aws_iam_policy" "secrets_access" {
  name = "ecsSecretsAccessPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          var.rds_secret_arn,
          var.redis_secret_arn,
          var.jwt_secret_arn
        ]
      }
    ]
  })
}

# Attach to both task roles
resource "aws_iam_role_policy_attachment" "payments_secrets_access" {
  role       = aws_iam_role.payments_task_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "kyc_secrets_access" {
  role       = aws_iam_role.kyc_task_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

###############################################
# EXECUTION ROLE EXTRA SECRETS ACCESS (OPTIONAL)
###############################################
resource "aws_iam_role_policy" "ecs_execution_secrets_access" {
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          var.rds_secret_arn,
          var.redis_secret_arn,
          var.jwt_secret_arn
        ]
      }
    ]
  })
}

###############################################
# ECS TASK S3 + KMS ACCESS POLICY
###############################################
resource "aws_iam_policy" "ecs_s3_access" {
  name = "ecs-s3-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3AccessForTasks"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.kyc_docs.arn,
          "${aws_s3_bucket.kyc_docs.arn}/*",
          aws_s3_bucket.exports.arn,
          "${aws_s3_bucket.exports.arn}/*"
        ]
      },
      {
        Sid    = "KMSForS3Data"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = aws_kms_key.s3_data_kms.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "payments_s3" {
  role       = aws_iam_role.payments_task_role.name
  policy_arn = aws_iam_policy.ecs_s3_access.arn
}

resource "aws_iam_role_policy_attachment" "kyc_s3" {
  role       = aws_iam_role.kyc_task_role.name
  policy_arn = aws_iam_policy.ecs_s3_access.arn
}

###############################################
# OUTPUTS
###############################################
output "execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "payments_task_role_arn" {
  value = aws_iam_role.payments_task_role.arn
}

output "kyc_task_role_arn" {
  value = aws_iam_role.kyc_task_role.arn
}
