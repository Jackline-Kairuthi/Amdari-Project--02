package terraform.alb

deny contains msg if {
  some idx
  sg := input.resource_changes[idx]
  sg.type == "aws_security_group"

  # Only check SGs attached to ALB
  contains(sg.address, "alb")

  some i
  rule := sg.change.after.ingress[i]

  rule.cidr_blocks[_] == "0.0.0.0/0"
  rule.from_port != 443
  rule.from_port != 80

  msg := sprintf("ALB SG %v allows public ingress on port %v", [sg.address, rule.from_port])
}






