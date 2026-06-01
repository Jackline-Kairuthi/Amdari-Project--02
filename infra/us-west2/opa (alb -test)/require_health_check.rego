package terraform.alb

# No health check block at all
deny contains msg if {
  some idx
  tg := input.resource_changes[idx]
  tg.type == "aws_lb_target_group"
  tg.change.after.health_check == null

  msg := sprintf("Target group %v has no health check defined", [tg.address])
}

# Health check exists but disabled
deny contains msg if {
  some idx
  tg := input.resource_changes[idx]
  tg.type == "aws_lb_target_group"
  hc := tg.change.after.health_check
  hc != null
  hc[0].enabled == false

  msg := sprintf("Target group %v has health check disabled", [tg.address])
}
