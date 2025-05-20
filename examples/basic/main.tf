provider "aws" {
  region = var.region
}

module "wordpress" {
  source = "/../.."
  version = "1.0.0"
  providers = {
    aws = aws
  }
  # VPC Configuration
  # Uncomment to use Terraform Cloud/Enterprise

  name        = var.name
  environment = var.environment
  region      = var.region
  
  vpc_cidr = var.vpc_cidr
  
  domain_name = var.domain_name
  
  # RDS Configuration
  rds_username = var.rds_username
  rds_password = var.rds_password
  
  # Simplified configuration
  enable_cdn          = false
  enable_cache        = false
  multi_az_rds        = false
  create_rds_replica  = false
  enable_bastion      = true
  wordpress_min_size  = 1
  wordpress_max_size  = 2
  wordpress_desired_capacity = 1
  
  # SSH access
  ssh_key_name = var.ssh_key_name
  
  tags = var.tags
}


