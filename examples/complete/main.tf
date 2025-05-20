provider "aws" {
  region = var.region
}

module "wordpress" {
  source = "/../.."
  version = "3.0.0"
  providers = {
    aws = aws
  }
  # VPC Configuration

  name        = var.name
  environment = var.environment
  region      = var.region
  azs         = var.azs
  
  vpc_cidr            = var.vpc_cidr
  public_subnets      = var.public_subnets
  private_app_subnets = var.private_app_subnets
  private_data_subnets = var.private_data_subnets
  
  domain_name = var.domain_name
  
  # RDS Configuration
  rds_instance_class    = var.rds_instance_class
  rds_allocated_storage = var.rds_allocated_storage
  multi_az_rds          = var.multi_az_rds
  rds_username          = var.rds_username
  rds_password          = var.rds_password
  create_rds_replica    = var.create_rds_replica
  
  # WordPress Configuration
  wordpress_instance_type    = var.wordpress_instance_type
  wordpress_min_size         = var.wordpress_min_size
  wordpress_max_size         = var.wordpress_max_size
  wordpress_desired_capacity = var.wordpress_desired_capacity
  
  # Bastion Configuration
  enable_bastion        = var.enable_bastion
  bastion_instance_type = var.bastion_instance_type
  ssh_key_name          = var.ssh_key_name
  allowed_ips           = var.allowed_ips
  
  # Cache Configuration
  enable_cache = var.enable_cache
  
  # CDN Configuration
  enable_cdn = var.enable_cdn
  
  # SSL Configuration
  ssl_certificate_arn = var.ssl_certificate_arn
  
  # Route53 Configuration
  create_route53_zone = var.create_route53_zone
  
  # NAT Gateway Configuration
  create_nat_gateway = var.create_nat_gateway
  
  # Tags
  tags = var.tags
}