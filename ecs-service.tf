###############################################
# PAYMENTS API SERVICE
###############################################
resource "aws_ecs_service" "payments_api" {
  name            = "payments-api-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.payments_api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_controller {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.payments_tg_arn
    container_name   = "payments-api"
    container_port   = 8000
  }

  depends_on = [
    aws_ecs_task_definition.payments_api
  ]
}

###############################################
# KYC API SERVICE
###############################################
resource "aws_ecs_service" "kyc_api" {
  name            = "kyc-api-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.kyc_api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_controller {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.kyc_tg_arn
    container_name   = "kyc-api"
    container_port   = 8001
  }

  depends_on = [
    aws_ecs_task_definition.kyc_api
  ]
}


