output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.wordpress.vpc_id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.wordpress.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "List of IDs of private app subnets"
  value       = module.wordpress.private_app_subnet_ids
}

output "private_data_subnet_ids" {
  description = "List of IDs of private data subnets"
  value       = module.wordpress.private_data_subnet_ids
}

output "nat_gateway_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.wordpress.nat_gateway_ips
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.wordpress.bastion_public_ip
}

output "rds_master_endpoint" {
  description = "The endpoint of the RDS master instance"
  value       = module.wordpress.rds_master_endpoint
}

output "rds_replica_endpoint" {
  description = "The endpoint of the RDS replica instance"
  value       = module.wordpress.rds_replica_endpoint
}

output "cache_endpoint" {
  description = "The endpoint of the ElastiCache cluster"
  value       = module.wordpress.cache_endpoint
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.wordpress.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = module.wordpress.cloudfront_domain_name
}

output "wordpress_site_url" {
  description = "The URL of the WordPress site"
  value       = module.wordpress.wordpress_site_url
}