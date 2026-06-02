
# Security Group for RDS Cluster
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow PostgreSQL access from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.lambda_sg_id]
  }

  egress {
    description = "Allow RDS to communicate within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "rds-sg"
  }
}

# Security Group for ElastiCache Cluster (Redis)
resource "aws_security_group" "redis_sg" {
  name        = "redis-sg"
  description = "Security group for Redis"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow Redis access from ECS tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.lambda_sg_id]
  }

  egress {
    description = "Allow Redis to communicate within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]   # FIX: restrict egress
  }

  tags = {
    Name = "redis-sg"
  }
}




