###############################################
# PAYMENTS API TASK DEFINITION
###############################################
resource "aws_ecs_task_definition" "payments_api" {
  family                   = "payments-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.payments_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "payments-api"
      image     = var.payments_image
      essential = true

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "DB_HOST",     value = var.rds_endpoint },
        { name = "DB_NAME",     value = "sentinelpaydb" },
        { name = "REDIS_HOST",  value = var.redis_endpoint },
        { name = "REDIS_PORT",  value = "6379" }
      ]

      secrets = [
        { name = "DB_USERNAME",     valueFrom = var.rds_secret_arn },
        { name = "DB_PASSWORD",     valueFrom = var.rds_secret_arn },
        { name = "REDIS_AUTH_TOKEN", valueFrom = var.redis_secret_arn },
        { name = "JWT_SECRET",       valueFrom = var.jwt_secret_arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/payments-api"
          awslogs-region        = "us-west-1"
          awslogs-stream-prefix = "payments"
        }
      }
    }
  ])
}

###############################################
# KYC API TASK DEFINITION
###############################################
resource "aws_ecs_task_definition" "kyc_api" {
  family                   = "kyc-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.kyc_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "kyc-api"
      image     = var.kyc_image
      essential = true

      portMappings = [
        {
          containerPort = 8001
          hostPort      = 8001
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "DB_HOST",     value = var.rds_endpoint },
        { name = "DB_NAME",     value = "sentinelpaydb" },
        { name = "REDIS_HOST",  value = var.redis_endpoint },
        { name = "REDIS_PORT",  value = "6379" }
      ]

      secrets = [
        { name = "DB_USERNAME",     valueFrom = var.rds_secret_arn },
        { name = "DB_PASSWORD",     valueFrom = var.rds_secret_arn },
        { name = "REDIS_AUTH_TOKEN", valueFrom = var.redis_secret_arn },
        { name = "JWT_SECRET",       valueFrom = var.jwt_secret_arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/kyc-api"
          awslogs-region        = "us-west-1"
          awslogs-stream-prefix = "kyc"
        }
      }
    }
  ])
}

