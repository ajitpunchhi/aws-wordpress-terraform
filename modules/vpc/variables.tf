variable "name" {
  description = "Name to be used on all resources as identifier"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "A list of availability zones in the region"
  type        = list(string)
}

variable "public_subnets" {
  description = "A list of public subnet CIDRs"
  type        = list(string)
}

variable "private_app_subnets" {
  description = "A list of private app subnet CIDRs"
  type        = list(string)
}

variable "private_data_subnets" {
  description = "A list of private data subnet CIDRs"
  type        = list(string)
}

variable "create_nat_gateway" {
  description = "Whether to create NAT Gateways in the public subnets"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Whether to create a VPN Gateway"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}