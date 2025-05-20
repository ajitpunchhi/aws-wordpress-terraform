variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The subnet IDs to deploy the WordPress instances"
  type        = list(string)
}

variable "security_group_id" {
  description = "The security group ID for the WordPress instances"
  type        = string
}

variable "instance_type" {
  description = "The instance type for the WordPress servers"
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "The AMI ID to use for the WordPress instances"
  type        = string
  default     = ""
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 5
}

variable "desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = ""
}

variable "efs_id" {
  description = "The ID of the EFS file system"
  type        = string
}

variable "db_endpoint" {
  description = "The endpoint of the database"
  type        = string
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "cache_endpoint" {
  description = "The endpoint of the cache"
  type        = string
  default     = ""
}

variable "enable_cache" {
  description = "Whether to enable Redis cache"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

