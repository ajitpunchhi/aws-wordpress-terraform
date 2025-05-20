variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
  default     = "wordpress-basic"
}

variable "environment" {
  description = "Environment name, e.g. 'dev', 'staging', 'prod'"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region to deploy the resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Domain name for the WordPress site"
  type        = string
  default     = "example.com"
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

variable "ssh_key_name" {
  description = "Name of the SSH key pair to use"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    Project     = "WordPress"
    Environment = "Development"
    Terraform   = "true"
  }
}
