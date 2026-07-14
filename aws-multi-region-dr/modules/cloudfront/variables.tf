variable "name_prefix" {
  description = "Name prefix. No hardcoded names."
  type        = string
}

variable "primary_origin_domain" {
  description = "DNS name of the primary ALB (primary origin)."
  type        = string
}

variable "dr_origin_domain" {
  description = "DNS name of the DR ALB (failover origin)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
