resource "aws_elasticache_subnet_group" "this" {
  name        = "${var.name}-${var.environment}-cache-subnet-group"
  description = "Cache subnet group for ${var.name}-${var.environment}"
  subnet_ids  = var.subnet_ids
}

resource "aws_elasticache_parameter_group" "this" {
  name        = "${var.name}-${var.environment}-cache-parameter-group"
  description = "Cache parameter group for ${var.name}-${var.environment}"
  family      = "redis6.x"
  
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id          = "${var.name}-${var.environment}-cache"
  description                   = "Redis cluster for ${var.name}-${var.environment}"
  
  node_type                     = var.node_type
  port                          = var.port
  engine                        = var.engine
  engine_version                = var.engine_version
  
  parameter_group_name          = aws_elasticache_parameter_group.this.name
  subnet_group_name             = aws_elasticache_subnet_group.this.name
  security_group_ids            = [var.security_group_id]
  
  num_cache_clusters            = var.num_cache_nodes
  automatic_failover_enabled    = var.automatic_failover_enabled
  
  maintenance_window            = var.maintenance_window
  
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  
  tags = merge(
    {
      "Name" = format("%s-%s-cache", var.name, var.environment)
    },
    var.tags,
  )
}

