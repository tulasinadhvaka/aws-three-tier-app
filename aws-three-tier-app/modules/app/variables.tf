variable "name" {
  description = "Name prefix for app-tier resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the app security group in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the app-tier ASG (>= 2 AZs)."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB security group — app tier only accepts traffic from this."
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group the ASG registers instances into."
  type        = string
}

variable "app_port" {
  description = "Port the app listens on."
  type        = number
  default     = 8080
}

variable "instance_type" {
  description = "EC2 instance type for the app tier."
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Desired number of app instances."
  type        = number
  default     = 2
}

variable "instance_profile_name" {
  description = "IAM instance profile name (e.g. the SSM baseline from the foundation). Empty = none."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
