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

