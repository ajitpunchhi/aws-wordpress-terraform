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
  description = "The subnet IDs to deploy the RDS instances"
  type        = list(string)
}

variable "security_group_id" {
  description = "The security group ID for the RDS instances"
  type        = string
}

variable "multi_az" {
  description = "Whether to enable multi-AZ deployment"
  type        = bool
  default     = true
}

variable "instance_class" {
  description = "The instance class to use for the RDS instances"
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "The upper limit to which RDS can automatically scale the storage"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD)"
  type        = string
  default     = "gp2"
}

variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "The engine version to use"
  type        = string
  default     = "8.0"
}

variable "username" {
  description = "Username for the master DB user"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = "wordpress"
}

variable "parameter_group_name" {
  description = "Name of the DB parameter group to associate"
  type        = string
  default     = null
}

variable "option_group_name" {
  description = "Name of the DB option group to associate"
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created"
  type        = string
  default     = "03:00-05:00"
}

variable "maintenance_window" {
  description = "The window to perform maintenance in"
  type        = string
  default     = "Sun:00:00-Sun:03:00"
}

variable "create_replica" {
  description = "Whether to create a read replica"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-${var.environment}-db-subnet-group"
  description = "DB subnet group for ${var.name}-${var.environment}"
  subnet_ids  = var.subnet_ids
  
  tags = merge(
    {
      "Name" = format("%s-%s-db-subnet-group", var.name, var.environment)
    },
    var.tags,
  )
}

resource "aws_db_parameter_group" "this" {
  name        = "${var.name}-${var.environment}-db-parameter-group"
  description = "DB parameter group for ${var.name}-${var.environment}"
  family      = "${var.engine}${replace(var.engine_version, "/\\.[0-9]+$/", "")}"
  
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  
  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
  
  tags = merge(
    {
      "Name" = format("%s-%s-db-parameter-group", var.name, var.environment)
    },
    var.tags,
  )
}

resource "aws_db_instance" "master" {
  identifier             = "${var.name}-${var.environment}-db-master"
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  storage_type           = var.storage_type
  storage_encrypted      = true
  
  db_name                = var.db_name
  username               = var.username
  password               = var.password
  
  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.this.name
  option_group_name      = var.option_group_name
  
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  
  apply_immediately      = true
  skip_final_snapshot    = false
  final_snapshot_identifier = "${var.name}-${var.environment}-db-master-final-snapshot"
  deletion_protection    = true
  
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  
  tags = merge(
    {
      "Name" = format("%s-%s-db-master", var.name, var.environment)
    },
    var.tags,
  )
}

resource "aws_db_instance" "replica" {
  count = var.create_replica ? 1 : 0
  
  identifier             = "${var.name}-${var.environment}-db-replica"
  replicate_source_db    = aws_db_instance.master.identifier
  instance_class         = var.instance_class
  
  vpc_security_group_ids = [var.security_group_id]
  
  apply_immediately      = true
  skip_final_snapshot    = true
  
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  
  tags = merge(
    {
      "Name" = format("%s-%s-db-replica", var.name, var.environment)
    },
    var.tags,
  )
}

output "master_endpoint" {
  description = "The endpoint of the master RDS instance"
  value       = aws_db_instance.master.endpoint
}

output "master_arn" {
  description = "The ARN of the master RDS instance"
  value       = aws_db_instance.master.arn
}

output "replica_endpoint" {
  description = "The endpoint of the replica RDS instance"
  value       = var.create_replica ? aws_db_instance.replica[0].endpoint : null
}

output "replica_arn" {
  description = "The ARN of the replica RDS instance"
  value       = var.create_replica ? aws_db_instance.replica[0].arn : null
}

output "database_name" {
  description = "The name of the database"
  value       = var.db_name
}

output "db_subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}