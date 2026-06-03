variable "jwt_secret_arn" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}
