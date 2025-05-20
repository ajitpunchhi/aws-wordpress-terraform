variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The subnet IDs to deploy the bastion host"
  type        = list(string)
}

variable "security_group_id" {
  description = "The security group ID for the bastion host"
  type        = string
}

variable "ssh_key_name" {
  description = "The name of the SSH key pair"
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
  default     = {}
}


