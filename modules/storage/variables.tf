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
  description = "The subnet IDs to deploy the EFS mount targets"
  type        = list(string)
}

variable "security_group_id" {
  description = "The security group ID for the EFS mount targets"
  type        = string
}

variable "encrypted" {
  description = "Whether to enable encryption for the EFS file system"
  type        = bool
  default     = true
}

variable "performance_mode" {
  description = "The file system performance mode"
  type        = string
  default     = "generalPurpose"
}

variable "throughput_mode" {
  description = "Throughput mode for the file system"
  type        = string
  default     = "bursting"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

resource "aws_efs_file_system" "this" {
  creation_token = "${var.name}-${var.environment}-efs"
  
  encrypted        = var.encrypted
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  
  tags = merge(
    {
      "Name" = format("%s-%s-efs", var.name, var.environment)
    },
    var.tags,
  )
}

resource "aws_efs_mount_target" "this" {
  count = length(var.subnet_ids)
  
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = element(var.subnet_ids, count.index)
  security_groups = [var.security_group_id]
}

resource "aws_efs_access_point" "wordpress" {
  file_system_id = aws_efs_file_system.this.id
  
  posix_user {
    gid = 33  # www-data group ID
    uid = 33  # www-data user ID
  }
  
  root_directory {
    path = "/wordpress"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = "0755"
    }
  }
  
  tags = merge(
    {
      "Name" = format("%s-%s-efs-ap", var.name, var.environment)
    },
    var.tags,
  )
}

output "efs_id" {
  description = "The ID of the EFS file system"
  value       = aws_efs_file_system.this.id
}

output "efs_dns_name" {
  description = "The DNS name of the EFS file system"
  value       = aws_efs_file_system.this.dns_name
}

output "efs_access_point_id" {
  description = "The ID of the EFS access point"
  value       = aws_efs_access_point.wordpress.id
}

output "mount_targets" {
  description = "Map of mount targets created"
  value       = aws_efs_mount_target.this
}