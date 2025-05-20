output "instance_id" {
  description = "The ID of the bastion instance"
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "The public IP of the bastion instance"
  value       = aws_eip.bastion.public_ip
}

output "private_ip" {
  description = "The private IP of the bastion instance"
  value       = aws_instance.bastion.private_ip
}