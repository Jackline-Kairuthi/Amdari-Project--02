# Output the security group ID for the ALB
output "payments_tg_arn" {
  value = aws_lb_target_group.payments_tg.arn
}

output "kyc_tg_arn" {
  value = aws_lb_target_group.kyc_tg.arn
}

output "listener_arn" {
  value = aws_lb_listener.http.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "alb_arn" {
  value = aws_lb.sentinel_alb.arn
}
