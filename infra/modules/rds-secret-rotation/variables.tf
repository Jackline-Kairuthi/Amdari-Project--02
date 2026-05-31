variable "name" {
  type        = string
  description = "Base name for rotation resources"
}

variable "secret_arn" {
  type        = string
  description = "ARN of the RDS secret"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key used to encrypt the secret"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for Lambda VPC config"
}

variable "ecs_tasks_sg_id" {
  type        = string
  description = "Security group ID for Lambda rotation function"
}

variable "rotation_days" {
  type        = number
  default     = 30
  description = "Rotation interval in days"
}



