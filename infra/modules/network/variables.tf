# Variables for the network module. These variables define the CIDR blocks for the VPC and subnets, as well as the availability zones to be used. The VPC will be created with a CIDR block of
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs for private subnets"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "azs" {
  type        = list(string)
  description = "Availability zones"
  default     = ["us-west-2a", "us-west-2c"]
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}
