output "alerts_topic_arn" {
  value = aws_sns_topic.dr_alerts.arn
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.dr.dashboard_name
}
