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
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
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
# OUTPUTS (so root module can reference them)
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

#################################### 
# Note: The below policy is attached to the execution role, which is used by both tasks.
# This allows the tasks to read secrets from Secrets Manager when they run.
######################################
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

      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}
