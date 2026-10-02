module "networking" {
  source = "../../modules/networking"

  environment = var.environment
  vpc_cidr    = var.vpc_cidr

  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
}

module "web_server" {
  source = "../../modules/web_server"

  environment     = var.environment
  instance_type   = var.instance_type
  public_key_path = var.public_key_path
  my_ip           = var.my_ip
  vpc_id          = module.networking.vpc_id
  subnet_id       = module.networking.public_subnet_ids[0]

  enable_detailed_monitoring = var.enable_detailed_monitoring
}
