output "alb_dns_name" {
  description = "Open this URL in a browser to reach the app."
  value       = module.alb.alb_dns_name
}

output "db_endpoint" {
  description = "RDS connection endpoint (private, app-tier access only)."
  value       = module.database.db_endpoint
}

output "autoscaling_group_name" {
  value = module.app.autoscaling_group_name
}
