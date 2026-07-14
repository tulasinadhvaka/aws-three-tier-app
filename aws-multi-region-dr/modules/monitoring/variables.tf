variable "name_prefix" {
  description = "Name prefix. No hardcoded names."
  type        = string
}

variable "primary_health_check_id" {
  description = "Route 53 health check id to alarm on."
  type        = string
}

variable "notification_email" {
  description = "Email for DR alerts. Empty = topic only, no subscription."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
