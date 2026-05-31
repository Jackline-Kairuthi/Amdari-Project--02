# application load balancer for sentinel
resource "aws_lb" "sentinel_alb" {
  name               = "sentinel-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets
  
  tags = {
    Name = "sentinel-alb"
  }
}

#target group for payments API
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

#target group for kyc API
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

#HTTP listener for ALB. This listener listens for incoming HTTP requests on port 80 and forwards them to the appropriate target group based on the path. It uses a fixed response as the default action to return a 404 Not Found status for any requests that do not match the defined rules.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.sentinel_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# Listener rule for payments API. This rule forwards requests with the path pattern /payments/* to the payments target group, allowing the ALB to route traffic to the payments API service based on the URL path.
resource "aws_lb_listener_rule" "payments_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payments_tg.arn
  }

  condition {
    path_pattern {
      values = ["/payments/*"]
    }
  }
}

#Listener rule for kyc API. This rule forwards requests with the path pattern /kyc/* to the KYC target group, allowing the ALB to route traffic to the KYC API service based on the URL path.
resource "aws_lb_listener_rule" "kyc_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kyc_tg.arn
  }

  condition {
    path_pattern {
      values = ["/kyc/*"]
    }
  }
}

# Listener rule for health checks. This rule forwards requests with the path pattern /health to the payments target group, allowing the ALB to route health check requests to the payments API service. This is important for monitoring the health of the service and ensuring that it is functioning properly.
resource "aws_lb_listener_rule" "health_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 15

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

# This listener rule is crucial for the health monitoring of the payments API service. By forwarding requests with the path pattern /health to the payments target group, it allows the ALB to perform regular health checks on the payments API. This ensures that any issues with the service can be detected promptly, allowing for quick remediation and maintaining the overall reliability of the application.
resource "aws_lb_listener_rule" "payments_transactions_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 12

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payments_tg.arn
  }

  condition {
    path_pattern {
      values = ["/v1/transactions/*"]
    }
  }
}

#listener rule for payments auth. This rule forwards requests with the path pattern /v1/auth/* to the payments target group, allowing the ALB to route authentication-related requests to the payments API service based on the URL path. This is important for handling user authentication and ensuring that authentication requests are properly directed to the payments API.
resource "aws_lb_listener_rule" "payments_auth_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 11

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payments_tg.arn
  }

  condition {
    path_pattern {
      values = ["/v1/auth/*"]
    }
  }
}

