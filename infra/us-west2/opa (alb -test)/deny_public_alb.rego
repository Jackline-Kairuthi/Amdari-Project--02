package terraform.alb

deny contains msg if {
  some idx
  lb := input.resource_changes[idx]
  lb.type == "aws_lb"

  # ALB is internet-facing
  lb.change.after.internal == false

  msg := sprintf("ALB %v is internet-facing; internal ALB required", [lb.address])
}




