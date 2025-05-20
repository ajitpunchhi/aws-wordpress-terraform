###############################################################
# Outputs
###############################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.wordpress_vpc.id
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.wordpress.dns_name
}

output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.wordpress_master.address
}

output "bastion_public_ips" {
  description = "The public IPs of the bastion hosts"
  value       = aws_instance.bastion[*].public_ip
}

output "wordpress_security_group_id" {
  description = "The ID of the WordPress security group"
  value       = aws_security_group.wordpress.id
}

output "efs_id" {
  description = "The ID of the EFS file system"
  value       = aws_efs_file_system.wordpress.id
}

output "elasticache_endpoint" {
  description = "The endpoint of the ElastiCache cluster"
  value       = var.create_elasticache ? aws_elasticache_replication_group.wordpress[0].primary_endpoint_address : null
}