package terraform.security

required_tags := {"Environment", "Owner", "Project"}

deny contains msg if {
  some idx
  res := input.resource_changes[idx]
  tags := res.change.after.tags
  tags == null

  msg := sprintf("Resource %v has no tags", [res.address])
}

deny contains msg if {
  some idx
  res := input.resource_changes[idx]
  tags := res.change.after.tags
  tags != null

  missing := required_tags - {k | tags[k]}
  count(missing) > 0

  msg := sprintf("Resource %v is missing required tags: %v", [res.address, missing])
}





