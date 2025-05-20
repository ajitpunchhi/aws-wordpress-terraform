output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "asg_id" {
  description = "The ID of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.id
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.this.id
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = aws_lb_target_group.this.arn
}

output "iam_role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.wordpress.arn
}