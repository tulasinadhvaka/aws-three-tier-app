locals {
  tags = merge(var.tags, { Module = "monitoring" })
}

resource "aws_sns_topic" "dr_alerts" {
  name = "${var.name_prefix}-dr-alerts"
  tags = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.notification_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.dr_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# Alarm when the primary health check reports unhealthy — created in us-east-1
# because Route 53 publishes HealthCheckStatus there only.
resource "aws_cloudwatch_metric_alarm" "primary_unhealthy" {
  provider            = aws.useast1
  alarm_name          = "${var.name_prefix}-primary-region-unhealthy"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  dimensions          = { HealthCheckId = var.primary_health_check_id }
  statistic           = "Minimum"
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  period              = 60
  evaluation_periods  = 2
  alarm_description   = "Primary region health check is failing — DR failover expected."
  alarm_actions       = [aws_sns_topic.dr_alerts.arn]
  ok_actions          = [aws_sns_topic.dr_alerts.arn]
  tags                = local.tags
}

resource "aws_cloudwatch_dashboard" "dr" {
  dashboard_name = "${var.name_prefix}-dr"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Primary region health check"
          region = "us-east-1"
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", var.primary_health_check_id]
          ]
          period = 60
          stat   = "Minimum"
        }
      }
    ]
  })
}
