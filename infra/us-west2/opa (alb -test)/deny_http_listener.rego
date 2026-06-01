package terraform.alb

deny contains msg if {
  some idx
  listener := input.resource_changes[idx]
  listener.type == "aws_lb_listener"

  # HTTP listener detected
  listener.change.after.protocol == "HTTP"

  msg := sprintf("ALB listener %v uses HTTP instead of HTTPS", [listener.address])
}



