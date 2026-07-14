variable "name_prefix" {
  description = "Name prefix. No hardcoded names."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID to create failover records in."
  type        = string
}

variable "record_name" {
  description = "DNS record name (e.g. app.example.com)."
  type        = string
}

variable "primary_alb_dns" {
  description = "Primary ALB DNS name."
  type        = string
}

variable "primary_alb_zone_id" {
  description = "Primary ALB canonical hosted zone id."
  type        = string
}

variable "dr_alb_dns" {
  description = "DR ALB DNS name."
  type        = string
}

variable "dr_alb_zone_id" {
  description = "DR ALB canonical hosted zone id."
  type        = string
}

variable "health_check_path" {
  description = "Path Route 53 health check probes on the primary."
  type        = string
  default     = "/healthz"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
