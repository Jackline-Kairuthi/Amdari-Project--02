###############################################
# Data sources
###############################################
data "aws_region" "current" {}

###############################################
# Build Lambda Layer ZIP
###############################################

locals {
  lambda_src_dir  = "${path.module}/lambda"
}

###############################################
# Build Lambda ZIP (code only)
###############################################
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = local.lambda_src_dir
  output_path = "${path.module}/rotation.zip"
}

###############################################
# IAM Role for Rotation Lambda
###############################################
resource "aws_iam_role" "rotation_role" {
  name = "${var.name}-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "rotation_policy" {
  name = "${var.name}-rotation-policy"
  role = aws_iam_role.rotation_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = var.secret_arn
      },
      {
  Effect = "Allow"
  Action = [
    "ec2:CreateNetworkInterface",
    "ec2:DescribeNetworkInterfaces",
    "ec2:DeleteNetworkInterface",
    "ec2:AssignPrivateIpAddresses",
    "ec2:UnassignPrivateIpAddresses"
  ]
  Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      },
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

###############################################
# Rotation Lambda Function
###############################################
resource "aws_lambda_function" "rotation_lambda" {
  function_name = "${var.name}-rotation-lambda"
  role          = aws_iam_role.rotation_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  layers = [
    aws_lambda_layer_version.pymysql.arn
  ]

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.ecs_tasks_sg_id]
  }

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
    }
  }
}

###############################################
# Secret Rotation Resource
###############################################
resource "aws_secretsmanager_secret_rotation" "rotation" {
  secret_id           = var.secret_arn
  rotation_lambda_arn = aws_lambda_function.rotation_lambda.arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}

################################################
# Allow Secrets Manager to invoke the Lambda function
################################################
resource "aws_lambda_permission" "allow_secrets_manager" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation_lambda.function_name
  principal     = "secretsmanager.amazonaws.com"
}
