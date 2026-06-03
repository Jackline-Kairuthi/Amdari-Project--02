
###############################################
# ALB MODULE
###############################################
module "alb" {
  source         = "./modules/alb"
  vpc_id         = module.network.vpc_id
  vpc_cidr = module.network.vpc_cidr # FIX: pass VPC CIDR to ALB module
  public_subnets = module.network.public_subnets
  environment     = var.environment
}

###############################################
# ECS MODULE (FINAL, CORRECT)
###############################################
module "ecs" {
  source = "./modules/ecs"

  vpc_id          = module.network.vpc_id
  vpc_cidr        = module.network.vpc_cidr
  private_subnets = module.network.private_subnets
  ecs_security_group_id = module.network.ecs_tasks_sg_id

  rds_endpoint     = module.database.rds_endpoint
  redis_endpoint   = module.database.redis_endpoint

  rds_secret_arn   = module.database.rds_secret_arn
  redis_secret_arn = module.database.redis_secret_arn
  jwt_secret_arn   = var.jwt_secret_arn

  payments_tg_arn = module.alb.payments_tg_arn
  kyc_tg_arn      = module.alb.kyc_tg_arn

  payments_image = "137071594519.dkr.ecr.us-west-2.amazonaws.com/sentinelpay:patched3"
  kyc_image      = "137071594519.dkr.ecr.us-west-2.amazonaws.com/kyc-api:py312-v5"

  alb_arn = module.alb.alb_arn

}

###############################################
# DATABASE MODULE
###############################################
module "database" {
  source          = "./modules/database"

  vpc_id          = module.network.vpc_id
  vpc_cidr        = module.network.vpc_cidr
  private_subnets = module.network.private_subnets

  ecs_sg_id       = module.network.ecs_tasks_sg_id
  lambda_sg_id    = module.rds_secret_rotation.lambda_sg_id
}

###############################################
# Secrets Manager Rotation MODULE
###############################################
module "rds_secret_rotation" {
  source = "./modules/rds-secret-rotation"

  name               = "sentinelpay-rds"
  secret_arn         = module.database.rds_secret_arn
  kms_key_arn        = aws_kms_key.secrets.arn
  private_subnet_ids = module.network.private_subnets
  ecs_tasks_sg_id  = module.network.ecs_tasks_sg_id
  rotation_days      = 30
}






