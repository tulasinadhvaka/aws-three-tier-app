output "record_name" {
  value = var.record_name
}

output "primary_health_check_id" {
  value = aws_route53_health_check.primary.id
}
