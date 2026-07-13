output "db_endpoint" {
  description = "Connection endpoint (host:port) for the RDS instance."
  value       = aws_db_instance.this.endpoint
}

output "db_security_group_id" {
  description = "Security group ID of the database tier."
  value       = aws_security_group.db.id
}
