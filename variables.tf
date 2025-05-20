###############################################################
# Required Variables
###############################################################

variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project used for tagging and naming resources"
  type        = string
}

variable "environment" {
  description = "The environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

###############################################################
# Network Variables
###############################################################

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "private_data_subnet_cidrs" {
  description = "CIDR blocks for private data subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

###############################################################
# EC2 Variables
###############################################################

variable "ami_id" {
  description = "The AMI ID to use for WordPress instances"
  type        = string
}

variable "instance_type" {
  description = "The instance type for WordPress instances"
  type        = string
  default     = "t3.small"
}

variable "bastion_instance_type" {
  description = "The instance type for bastion hosts"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "The name of the key pair to use for SSH access"
  type        = string
}

variable "root_volume_size" {
  description = "The size of the root volume in GB"
  type        = number
  default     = 20
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to the bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

###############################################################
# Auto Scaling Variables
###############################################################

variable "min_size" {
  description = "Minimum number of WordPress instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of WordPress instances"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of WordPress instances"
  type        = number
  default     = 2
}

###############################################################
# Database Variables
###############################################################

variable "db_instance_class" {
  description = "The instance class of the RDS instance"
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "The allocated storage for the RDS instance in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "The maximum allocated storage for the RDS instance in GB"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "The name of the WordPress database"
  type        = string
  default     = "wordpress"
}

variable "db_username" {
  description = "The username for the WordPress database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the WordPress database"
  type        = string
  sensitive   = true
}

variable "create_db_replica" {
  description = "Whether to create a read replica for the RDS instance"
  type        = bool
  default     = true
}

variable "db_replica_instance_class" {
  description = "The instance class of the RDS read replica"
  type        = string
  default     = "db.t3.small"
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when the DB is deleted"
  type        = bool
  default     = false
}

###############################################################
# Cache Variables
###############################################################

variable "create_elasticache" {
  description = "Whether to create ElastiCache for caching"
  type        = bool
  default     = true
}

variable "elasticache_node_type" {
  description = "The node type for ElastiCache"
  type        = string
  default     = "cache.t3.small"
}

###############################################################
# Load Balancer Variables
###############################################################

variable "enable_https" {
  description = "Whether to enable HTTPS"
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for HTTPS"
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection for ALB and RDS"
  type        = bool
  default     = false
}

###############################################################
# Route 53 Variables
###############################################################

variable "create_route53_record" {
  description = "Whether to create a Route 53 record"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "The ID of the Route 53 hosted zone"
  type        = string
  default     = ""
}

variable "site_url" {
  description = "The URL of the WordPress site"
  type        = string
  default     = "example.com"
}

###############################################################
# Monitoring Variables
###############################################################

variable "alarm_sns_topic_arn" {
  description = "The ARN of the SNS topic for CloudWatch alarms"
  type        = string
  default     = ""
}