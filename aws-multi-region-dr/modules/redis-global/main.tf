locals {
  tags = merge(var.tags, { Module = "redis-global" })
}

# Subnet groups per region.
resource "aws_elasticache_subnet_group" "primary" {
  name       = "${var.name_prefix}-redis-primary"
  subnet_ids = var.primary_subnet_ids
  tags       = local.tags
}

resource "aws_elasticache_subnet_group" "dr" {
  provider   = aws.dr
  name       = "${var.name_prefix}-redis-dr"
  subnet_ids = var.dr_subnet_ids
  tags       = local.tags
}

# Primary replication group (source of the global datastore).
resource "aws_elasticache_replication_group" "primary" {
  replication_group_id = "${var.name_prefix}-redis-primary"
  description          = "${var.name_prefix} redis primary"
  node_type            = var.node_type
  engine_version       = var.engine_version
  num_cache_clusters   = 2
  subnet_group_name    = aws_elasticache_subnet_group.primary.name

  automatic_failover_enabled = true
  multi_az_enabled           = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = local.tags
}

# Global datastore ties primary + secondary together for cross-region replication.
resource "aws_elasticache_global_replication_group" "this" {
  global_replication_group_id_suffix = "${var.name_prefix}-global"
  primary_replication_group_id       = aws_elasticache_replication_group.primary.id
}

# Secondary replication group in the DR region, joined to the global datastore.
resource "aws_elasticache_replication_group" "dr" {
  provider                    = aws.dr
  replication_group_id        = "${var.name_prefix}-redis-dr"
  description                 = "${var.name_prefix} redis DR secondary"
  global_replication_group_id = aws_elasticache_global_replication_group.this.global_replication_group_id
  num_cache_clusters          = 2
  subnet_group_name           = aws_elasticache_subnet_group.dr.name

  automatic_failover_enabled = true
  multi_az_enabled           = true

  tags = local.tags
}
