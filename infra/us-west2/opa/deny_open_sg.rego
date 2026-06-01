package terraform.security

deny contains msg if {
  some idx
  sg := input.resource_changes[idx]
  sg.type == "aws_security_group"

  some i
  some j
  sg.change.after.ingress[i].cidr_blocks[j] == "0.0.0.0/0"

  msg := sprintf("Security Group %v allows ingress from 0.0.0.0/0", [sg.address])
}


