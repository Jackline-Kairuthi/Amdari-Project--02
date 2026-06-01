package terraform.security

deny contains msg if {
  some idx
  bucket := input.resource_changes[idx]
  bucket.type == "aws_s3_bucket"
  not bucket.change.after.server_side_encryption_configuration

  msg := sprintf("S3 bucket %v has no encryption enabled", [bucket.address])
}

deny contains msg if {
  some idx
  vol := input.resource_changes[idx]
  vol.type == "aws_ebs_volume"
  not vol.change.after.encrypted

  msg := sprintf("EBS volume %v is not encrypted", [vol.address])
}

deny contains msg if {
  some idx
  rds := input.resource_changes[idx]
  rds.type == "aws_rds_cluster"
  not rds.change.after.storage_encrypted

  msg := sprintf("RDS cluster %v is not encrypted", [rds.address])
}



