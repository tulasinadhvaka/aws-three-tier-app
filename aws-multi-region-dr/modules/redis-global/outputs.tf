output "global_replication_group_id" {
  value = aws_elasticache_global_replication_group.this.global_replication_group_id
}

output "primary_endpoint" {
  description = "Primary configuration endpoint."
  value       = aws_elasticache_replication_group.primary.primary_endpoint_address
}

output "dr_replication_group_id" {
  description = "DR replication group id (promoted on failover)."
  value       = aws_elasticache_replication_group.dr.id
}
