variable "name_prefix" {
  description = "Name prefix. No hardcoded names."
  type        = string
}

variable "vpc_id" {
  description = "VPC to place the ALB in."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the ALB (>= 2 AZs)."
  type        = list(string)
}

variable "health_check_path" {
  description = "Path the ALB + Route 53 health check probe."
  type        = string
  default     = "/healthz"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
