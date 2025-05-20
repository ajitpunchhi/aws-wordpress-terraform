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