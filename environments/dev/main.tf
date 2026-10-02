module "networking" {
  source = "../../modules/networking"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  # Required: instances live in private subnets and need outbound access for
  # package installation and the SSM agent.
  enable_nat_gateway = true
}

module "web_app" {
  source = "../../modules/web_app"

  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids

  instance_type    = var.instance_type
  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size

  enable_detailed_monitoring = var.enable_detailed_monitoring
  enable_deletion_protection = var.enable_deletion_protection
}
