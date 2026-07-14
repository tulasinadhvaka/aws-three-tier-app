locals {
  tags = merge(var.tags, { Module = "aurora-global" })
}

# ---------------------------------------------------------------------------
# Global cluster — the container that ties primary + DR together.
# ---------------------------------------------------------------------------
resource "aws_rds_global_cluster" "this" {
  global_cluster_identifier = "${var.name_prefix}-global"
  engine                    = var.engine
  engine_version            = var.engine_version
}

# ---------------------------------------------------------------------------
# PRIMARY region: subnet group, security group, cluster (writer) + instance.
# ---------------------------------------------------------------------------
resource "aws_db_subnet_group" "primary" {
  name       = "${var.name_prefix}-primary-subnets"
  subnet_ids = var.primary_subnet_ids
  tags       = local.tags
}

resource "aws_security_group" "primary" {
  name        = "${var.name_prefix}-primary-db-sg"
  description = "Aurora primary access"
  vpc_id      = var.primary_vpc_id
  ingress {
    description = "DB port from within VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
  }
  tags = merge(local.tags, { Name = "${var.name_prefix}-primary-db-sg" })
}

resource "aws_rds_cluster" "primary" {
  cluster_identifier        = "${var.name_prefix}-primary"
  engine                    = var.engine
  engine_version            = var.engine_version
  global_cluster_identifier = aws_rds_global_cluster.this.id
  master_username           = var.master_username
  master_password           = var.master_password
  db_subnet_group_name      = aws_db_subnet_group.primary.name
  vpc_security_group_ids    = [aws_security_group.primary.id]
  storage_encrypted         = true
  skip_final_snapshot       = true
  tags                      = local.tags
}

resource "aws_rds_cluster_instance" "primary" {
  identifier           = "${var.name_prefix}-primary-1"
  cluster_identifier   = aws_rds_cluster.primary.id
  instance_class       = var.instance_class
  engine               = var.engine
  engine_version       = var.engine_version
  db_subnet_group_name = aws_db_subnet_group.primary.name
  tags                 = local.tags
}

# ---------------------------------------------------------------------------
# DR region: subnet group, security group, secondary cluster (reader) + instance.
# The secondary joins the global cluster and replicates continuously (RPO ~1s).
# ---------------------------------------------------------------------------
resource "aws_db_subnet_group" "dr" {
  provider   = aws.dr
  name       = "${var.name_prefix}-dr-subnets"
  subnet_ids = var.dr_subnet_ids
  tags       = local.tags
}

resource "aws_security_group" "dr" {
  provider    = aws.dr
  name        = "${var.name_prefix}-dr-db-sg"
  description = "Aurora DR access"
  vpc_id      = var.dr_vpc_id
  ingress {
    description = "DB port from within VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
  }
  tags = merge(local.tags, { Name = "${var.name_prefix}-dr-db-sg" })
}

resource "aws_rds_cluster" "dr" {
  provider                  = aws.dr
  cluster_identifier        = "${var.name_prefix}-dr"
  engine                    = var.engine
  engine_version            = var.engine_version
  global_cluster_identifier = aws_rds_global_cluster.this.id
  db_subnet_group_name      = aws_db_subnet_group.dr.name
  vpc_security_group_ids    = [aws_security_group.dr.id]
  storage_encrypted         = true
  skip_final_snapshot       = true
  tags                      = local.tags

  # The secondary must be created after the primary is part of the global cluster.
  depends_on = [aws_rds_cluster_instance.primary]
}

resource "aws_rds_cluster_instance" "dr" {
  provider             = aws.dr
  identifier           = "${var.name_prefix}-dr-1"
  cluster_identifier   = aws_rds_cluster.dr.id
  instance_class       = var.instance_class
  engine               = var.engine
  engine_version       = var.engine_version
  db_subnet_group_name = aws_db_subnet_group.dr.name
  tags                 = local.tags
}
