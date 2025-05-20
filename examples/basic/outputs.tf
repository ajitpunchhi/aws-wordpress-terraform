output "wordpress_site_url" {
  description = "The URL of the WordPress site"
  value       = module.wordpress.wordpress_site_url
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.wordpress.alb_dns_name
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.wordpress.bastion_public_ip
}