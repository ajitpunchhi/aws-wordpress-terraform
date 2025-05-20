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

locals {
  max_subnet_length = max(
    length(var.public_subnets),
    length(var.private_app_subnets),
    length(var.private_data_subnets)
  )
  nat_gateway_count = var.create_nat_gateway ? min(length(var.public_subnets), local.max_subnet_length) : 0
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(
    {
      "Name" = format("%s-%s-vpc", var.name, var.environment)
    },
    var.tags,
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  
  tags = merge(
    {
      "Name" = format("%s-%s-igw", var.name, var.environment)
    },
    var.tags,
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)
  
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  
  tags = merge(
    {
      "Name" = format("%s-%s-public-subnet-%s", var.name, var.environment, element(var.azs, count.index))
      "Tier" = "Public"
    },
    var.tags,
  )
}

resource "aws_subnet" "private_app" {
  count = length(var.private_app_subnets)
  
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_app_subnets[count.index]
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false
  
  tags = merge(
    {
      "Name" = format("%s-%s-private-app-subnet-%s", var.name, var.environment, element(var.azs, count.index))
      "Tier" = "Private"
      "Type" = "App"
    },
    var.tags,
  )
}

resource "aws_subnet" "private_data" {
  count = length(var.private_data_subnets)
  
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_data_subnets[count.index]
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false
  
  tags = merge(
    {
      "Name" = format("%s-%s-private-data-subnet-%s", var.name, var.environment, element(var.azs, count.index))
      "Tier" = "Private"
      "Type" = "Data"
    },
    var.tags,
  )
}

resource "aws_eip" "nat" {
  count = local.nat_gateway_count
  
  domain = "vpc"
  
  tags = merge(
    {
      "Name" = format("%s-%s-eip-%s", var.name, var.environment, element(var.azs, count.index))
    },
    var.tags,
  )
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count
  
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  
  tags = merge(
    {
      "Name" = format("%s-%s-nat-%s", var.name, var.environment, element(var.azs, count.index))
    },
    var.tags,
  )
  
  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  
  tags = merge(
    {
      "Name" = format("%s-%s-public-rt", var.name, var.environment)
    },
    var.tags,
  )
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table" "private" {
  count = local.nat_gateway_count
  
  vpc_id = aws_vpc.this.id
  
  tags = merge(
    {
      "Name" = format("%s-%s-private-rt-%s", var.name, var.environment, element(var.azs, count.index))
    },
    var.tags,
  )
}

resource "aws_route" "private_nat_gateway" {
  count = local.nat_gateway_count
  
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)
  
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app" {
  count = length(var.private_app_subnets)
  
  subnet_id      = element(aws_subnet.private_app.*.id, count.index)
  route_table_id = element(
    aws_route_table.private.*.id,
    count.index % local.nat_gateway_count,
  )
}

resource "aws_route_table_association" "private_data" {
  count = length(var.private_data_subnets)
  
  subnet_id      = element(aws_subnet.private_data.*.id, count.index)
  route_table_id = element(
    aws_route_table.private.*.id,
    count.index % local.nat_gateway_count,
  )
}

resource "aws_vpn_gateway" "this" {
  count = var.enable_vpn_gateway ? 1 : 0
  
  vpc_id = aws_vpc.this.id
  
  tags = merge(
    {
      "Name" = format("%s-%s-vpn-gateway", var.name, var.environment)
    },
    var.tags,
  )
}

