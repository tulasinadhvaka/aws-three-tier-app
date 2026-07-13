variable "name" {
  description = "Name prefix for ALB resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the ALB and target group in."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the internet-facing ALB (>= 2 AZs)."
  type        = list(string)
}

variable "app_port" {
  description = "Port the app tier listens on (ALB forwards here)."
  type        = number
  default     = 8080
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
