package terraform.alb

# Missing TLS policy (empty string)
deny contains msg if {
  some idx
  listener := input.resource_changes[idx]
  listener.type == "aws_lb_listener"
  listener.change.after.protocol == "HTTPS"
  ssl := listener.change.after.ssl_policy
  ssl == ""

  msg := sprintf("ALB listener %v has no TLS policy configured", [listener.address])
}

# Missing TLS policy (null)
deny contains msg if {
  some idx
  listener := input.resource_changes[idx]
  listener.type == "aws_lb_listener"
  listener.change.after.protocol == "HTTPS"
  ssl := listener.change.after.ssl_policy
  ssl == null

  msg := sprintf("ALB listener %v has no TLS policy configured", [listener.address])
}

# Weak TLS policy
deny contains msg if {
  some idx
  listener := input.resource_changes[idx]
  listener.type == "aws_lb_listener"
  listener.change.after.protocol == "HTTPS"
  ssl := listener.change.after.ssl_policy
  ssl == "ELBSecurityPolicy-2016-08"

  msg := sprintf("ALB listener %v uses weak TLS policy: %v", [listener.address, ssl])
}

