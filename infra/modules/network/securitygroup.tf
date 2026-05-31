# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  # Allow ALB → Payments API
  ingress {
    description     = "Allow ALB to reach Payments API"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Allow ALB → KYC API
  ingress {
    description     = "Allow ALB to reach KYC API"
    from_port       = 8001
    to_port         = 8001
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Outbound allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-tasks-sg"
  }
}



