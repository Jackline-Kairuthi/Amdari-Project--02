###############################################
# APPLICATION LOAD BALANCER
###############################################
resource "aws_lb" "sentinel_alb" {
  name               = "sentinel-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets

  # Fix: Enable ALB access logging
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    enabled = true
  }

  # Fix: Enable deletion protection
  enable_deletion_protection = true

  # Fix: Drop invalid HTTP headers
  drop_invalid_header_fields = true

  tags = {
    Name = "sentinel-alb"
  }
}


###############################################
# TARGET GROUPS
###############################################
resource "aws_lb_target_group" "payments_tg" {
  name        = "payments-tg"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "kyc_tg" {
  name        = "kyc-tg"
  port        = 8001
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

###############################################
# HTTP LISTENER (PRIMARY)
###############################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.sentinel_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

###############################################
# HEALTH CHECK ROUTING
###############################################
resource "aws_lb_listener_rule" "health_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payments_tg.arn
  }

  condition {
    path_pattern {
      values = ["/health"]
    }
  }
}

###############################################
# PAYMENTS API ROUTING
###############################################
resource "aws_lb_listener_rule" "payments_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payments_tg.arn
  }

  condition {
    path_pattern {
      values = [
        "/v1/auth/*",
        "/v1/transactions/*"
      ]
    }
  }
}

###############################################
# KYC API ROUTING
###############################################
resource "aws_lb_listener_rule" "kyc_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kyc_tg.arn
  }

  condition {
    path_pattern {
      values = [
        "/v1/verify/*",
        "/v1/documents/*"
      ]
    }
  }
}

################################################
# S3 BUCKET FOR ALB ACCESS LOGS
################################################
resource "aws_s3_bucket" "alb_logs" {
  bucket = "sentinel-alb-logs-${var.environment}"
  force_destroy = true

  tags = {
    Name = "sentinel-alb-logs"
  }
}

################################################
# KMS KEY FOR SECRETS
################################################
resource "aws_kms_key" "secrets" {
  description = "KMS key for RDS and Redis secrets"
  deletion_window_in_days = 7
}


