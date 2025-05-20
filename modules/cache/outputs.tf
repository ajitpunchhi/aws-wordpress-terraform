output "id" {
  description = "The ID of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.this.id
}

output "endpoint" {
  description = "The endpoint of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint" {
  description = "The reader endpoint of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  description = "The port of the ElastiCache replication group"
  value       = aws_elasticache_replication_group.this.port
}