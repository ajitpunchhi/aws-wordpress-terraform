
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
  description = "The subnet IDs to deploy the load balancer"
  type        = list(string)
}

variable "security_group_id" {
  description = "The security group ID for the load balancer"
  type        = string
}

variable "target_group_arn" {
  description = "The ARN of the target group"
  type        = string
}

variable "ssl_certificate_arn" {
  description = "The ARN of the SSL certificate"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "The domain name for the site"
  type        = string
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "Whether to enable deletion protection for the load balancer"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}