module "network" {
  source = "./modules/network"

  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  azs                 = ["us-west-2a", "us-west-2c"]
  alb_security_group_id = module.alb.alb_sg_id
  vpc_id              = module.network.vpc_id # Pass VPC ID to network module
}

# drift trigger
# drift trigger
# drift trigger
# drift trigger
# drift trigger 3
# drift trigger
# drift trigger
# drift trigger
# reset drift
# clean state
