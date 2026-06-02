# This Terraform configuration defines an AWS Elastic Container Registry (ECR) repository for the SentinelPay application. The repository is configured to allow mutable image tags, use KMS encryption, and enable image scanning on push. Additionally, a lifecycle policy is set to keep only the last 10 images and expire older ones to manage storage costs effectively.

resource "aws_ecr_repository" "sentinelpay" {
  name                 = "sentinelpay"
  image_tag_mutability = "IMMUTABLE"

  encryption_configuration {
    encryption_type = "KMS"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "sentinelpay"
  }
}


# ECR lifecycle policy to keep only the last 10 images and expire older ones
resource "aws_ecr_lifecycle_policy" "sentinelpay" {
  repository = aws_ecr_repository.sentinelpay.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
