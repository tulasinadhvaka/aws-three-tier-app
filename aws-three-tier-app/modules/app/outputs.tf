output "app_security_group_id" {
  description = "Security group ID of the app tier (DB tier allows traffic from this)."
  value       = aws_security_group.app.id
}

output "autoscaling_group_name" {
  description = "Name of the app-tier Auto Scaling Group."
  value       = aws_autoscaling_group.app.name
}
