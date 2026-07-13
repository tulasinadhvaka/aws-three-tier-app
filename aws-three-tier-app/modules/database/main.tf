locals {
  tags = merge(var.tags, { Module = "database", Tier = "data" })
}

# DB security group: only the app tier may reach the DB port. Never public.
resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "Allow DB-port traffic only from the app tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "DB port from app tier only"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  # No egress needed for RDS; keep it closed by omitting egress rules.

  tags = merge(local.tags, { Name = "${var.name}-db-sg" })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = merge(local.tags, { Name = "${var.name}-db-subnets" })
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name}-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  multi_az               = var.multi_az
  publicly_accessible    = false

  backup_retention_period = 7
  skip_final_snapshot     = true # demo convenience; set false + snapshot id for prod
  deletion_protection     = false

  tags = merge(local.tags, { Name = "${var.name}-db" })
}
