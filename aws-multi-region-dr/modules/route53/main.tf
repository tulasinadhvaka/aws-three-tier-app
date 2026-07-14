locals {
  tags = merge(var.tags, { Module = "route53" })
}

# Health check against the PRIMARY ALB. When it fails, Route 53 stops
# answering with the primary record and serves the secondary.
resource "aws_route53_health_check" "primary" {
  fqdn              = var.primary_alb_dns
  port              = 80
  type              = "HTTP"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30
  tags              = merge(local.tags, { Name = "${var.name_prefix}-primary-hc" })
}

# PRIMARY failover record — served while the health check is healthy.
resource "aws_route53_record" "primary" {
  zone_id        = var.hosted_zone_id
  name           = var.record_name
  type           = "A"
  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id

  alias {
    name                   = var.primary_alb_dns
    zone_id                = var.primary_alb_zone_id
    evaluate_target_health = true
  }
}

# SECONDARY failover record — served when the primary health check fails.
resource "aws_route53_record" "secondary" {
  zone_id        = var.hosted_zone_id
  name           = var.record_name
  type           = "A"
  set_identifier = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.dr_alb_dns
    zone_id                = var.dr_alb_zone_id
    evaluate_target_health = true
  }
}
