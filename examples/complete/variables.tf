variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
  default     = "wordpress"
}

variable "environment" {
  description = "Environment name, e.g. 'dev', 'staging', 'prod'"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region to deploy the resources"
  type        = string
  default     = "us-east-1"
}

variable "azs" {
  description = "A list of availability zones in the region"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "A list of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnets" {
  description = "A list of private app subnet CIDRs"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_data_subnets" {
  description = "A list of private data subnet CIDRs"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "domain_name" {
  description = "Domain name for the WordPress site"
  type        = string
  default     = "example.com"
}

variable "create_route53_zone" {
  description = "Whether to create a Route53 zone for the domain"
  type        = bool
  default     = false
}

variable "enable_cdn" {
  description = "Whether to enable CloudFront CDN"
  type        = bool
  default     = true
}

variable "enable_cache" {
  description = "Whether to enable Redis/ElastiCache"
  type        = bool
  default     = true
}

variable "enable_bastion" {
  description = "Whether to deploy a bastion host"
  type        = bool
  default     = true
}

variable "multi_az_rds" {
  description = "Whether to enable multi-AZ for RDS"
  type        = bool
  default     = true
}

variable "wordpress_instance_type" {
  description = "Instance type for the WordPress servers"
  type        = string
  default     = "t3.small"
}

variable "wordpress_min_size" {
  description = "Minimum number of WordPress instances"
  type        = number
  default     = 2
}

variable "wordpress_max_size" {
  description = "Maximum number of WordPress instances"
  type        = number
  default     = 5
}

variable "wordpress_desired_capacity" {
  description = "Desired number of WordPress instances"
  type        = number
  default     = 2
}

variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "rds_instance_class" {
  description = "Instance class for the RDS instances"
  type        = string
  default     = "db.t3.small"
}

variable "rds_allocated_storage" {
  description = "Allocated storage for the RDS instances in GB"
  type        = number
  default     = 20
}

variable "rds_username" {
  description = "Username for the RDS instances"
  type        = string
  default     = "wordpress_user"
  sensitive   = true
}

variable "rds_password" {
  description = "Password for the RDS instances"
  type        = string
  sensitive   = true
}

variable "create_rds_replica" {
  description = "Whether to create an RDS replica"
  type        = bool
  default     = true
}

variable "ssl_certificate_arn" {
  description = "ARN of an SSL certificate to use with CloudFront/ALB"
  type        = string
  default     = ""
}

variable "create_nat_gateway" {
  description = "Whether to create NAT Gateways in the public subnets"
  type        = bool
  default     = true
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair to use"
  type        = string
  default     = ""
}

variable "allowed_ips" {
  description = "List of IPs allowed to connect to the bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    Project     = "WordPress"
    Environment = "Production"
    Terraform   = "true"
  }
}