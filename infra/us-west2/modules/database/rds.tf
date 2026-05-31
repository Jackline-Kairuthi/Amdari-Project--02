#RDS subnet group for SentinelPay (connects RDS to private subnets created in main.tf)
resource "aws_db_subnet_group" "rds" {
  name       = "sentinelpay-rds-subnet-group"
  subnet_ids = var.private_subnets

  tags = {
    Name = "sentinelpay-rds-subnet-group"
  }
}

# Create KMS key for Aurora POSTGRESQL
resource "aws_kms_key" "rds" {
  description             = "KMS key for Aurora POSTGRESQL encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "rds_alias" {
  name          = "alias/sentinelpay-rds-kms"
  target_key_id = aws_kms_key.rds.key_id
}

# RDS Cluster for SentinelPay
resource "aws_rds_cluster" "sentinel" {
  cluster_identifier      = "sentinelpay-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "17.7" # or latest supported
  database_name           = "sentinelpaydb"

  master_username         = "sentinelpayadmin"
  master_password         = random_password.rds.result

  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"

  kms_key_id              = aws_kms_key.rds.arn
  storage_encrypted       = true

  db_subnet_group_name    = aws_db_subnet_group.rds.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]

  skip_final_snapshot     = true
}

# Note: Aurora clusters require at least one instance to be functional. We create two instances for high availability.
resource "aws_rds_cluster_instance" "sentinel_instances" {
  count              = 2
  identifier         = "sentinelpay-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.sentinel.id
  instance_class     = "db.t3.medium"
  engine             = aws_rds_cluster.sentinel.engine
  engine_version     = aws_rds_cluster.sentinel.engine_version
}


