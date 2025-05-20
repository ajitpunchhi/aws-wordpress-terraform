output "alb_security_group_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "bastion_security_group_id" {
  description = "The ID of the Bastion security group"
  value       = aws_security_group.bastion.id
}

output "wordpress_security_group_id" {
  description = "The ID of the WordPress security group"
  value       = aws_security_group.wordpress.id
}

output "database_security_group_id" {
  description = "The ID of the Database security group"
  value       = aws_security_group.database.id
}

output "cache_security_group_id" {
  description = "The ID of the Cache security group"
  value       = aws_security_group.cache.id
}

output "efs_security_group_id" {
  description = "The ID of the EFS security group"
  value       = aws_security_group.efs.id
}