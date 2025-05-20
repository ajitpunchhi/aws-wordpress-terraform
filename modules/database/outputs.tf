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