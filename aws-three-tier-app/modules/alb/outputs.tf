output "alb_dns_name" {
  description = "Public DNS name of the ALB — open this in a browser."
  value       = aws_lb.this.dns_name
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB (app tier allows traffic from this)."
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "ARN of the target group the ASG registers into."
  value       = aws_lb_target_group.app.arn
}
