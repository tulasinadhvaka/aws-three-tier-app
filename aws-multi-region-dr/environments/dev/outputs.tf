output "cloudfront_domain" {
  description = "Public entry point — CloudFront distribution domain."
  value       = module.cloudfront.distribution_domain_name
}

output "app_dns_record" {
  description = "Route 53 failover record for the app."
  value       = module.route53.record_name
}

output "aurora_primary_endpoint" {
  value = module.aurora.primary_endpoint
}

output "aurora_dr_cluster_id" {
  description = "DR Aurora cluster id — used by scripts/promote-aurora.sh on failover."
  value       = module.aurora.dr_cluster_id
}

output "redis_dr_replication_group_id" {
  value = module.redis.dr_replication_group_id
}

output "s3_primary_bucket" {
  value = module.s3.primary_bucket
}

output "dr_alerts_topic_arn" {
  value = module.monitoring.alerts_topic_arn
}
