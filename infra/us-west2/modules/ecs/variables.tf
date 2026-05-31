###############################################
# NETWORKING
###############################################
variable "vpc_id" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "ecs_security_group_id" {
  type = string
}

###############################################
# LOAD BALANCER / TARGET GROUPS
###############################################
variable "payments_tg_arn" {
  type = string
}

variable "kyc_tg_arn" {
  type = string
}

# Optional: used to enforce ordering so ECS service waits for TG
variable "payments_tg_depends_on" {
  type    = any
  default = null
}

variable "kyc_tg_depends_on" {
  type    = any
  default = null
}

###############################################
# IMAGES
###############################################
variable "payments_image" {
  type = string
}

variable "kyc_image" {
  type = string
}

###############################################
# DATABASE + REDIS ENDPOINTS
###############################################
variable "rds_endpoint" {
  type = string
}

variable "redis_endpoint" {
  type = string
}

###############################################
# SECRETS (ARNs)
###############################################
variable "rds_secret_arn" {
  type = string
}

variable "redis_secret_arn" {
  type = string
}

variable "jwt_secret_arn" {
  type = string
}




