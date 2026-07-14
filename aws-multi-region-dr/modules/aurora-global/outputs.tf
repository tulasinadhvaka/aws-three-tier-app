output "global_cluster_id" {
  value = aws_rds_global_cluster.this.id
}

output "primary_endpoint" {
  description = "Writer endpoint (primary region)."
  value       = aws_rds_cluster.primary.endpoint
}

output "dr_reader_endpoint" {
  description = "Reader endpoint (DR region) — becomes writer after promotion."
  value       = aws_rds_cluster.dr.reader_endpoint
}

output "dr_cluster_id" {
  description = "DR cluster id (used by the promote script on failover)."
  value       = aws_rds_cluster.dr.cluster_identifier
}
