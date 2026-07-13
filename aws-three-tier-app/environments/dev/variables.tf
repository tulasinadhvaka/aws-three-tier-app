variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "Existing VPC ID (e.g. output of aws-terraform-foundation)."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB (>= 2 AZs)."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for app + db tiers (>= 2 AZs)."
  type        = list(string)
}

variable "app_port" {
  description = "Port the app tier listens on."
  type        = number
  default     = 8080
}

variable "instance_count" {
  description = "Desired app-tier instance count."
  type        = number
  default     = 2
}

variable "instance_profile_name" {
  description = "IAM instance profile for app servers (SSM baseline). Empty = none."
  type        = string
  default     = ""
}

variable "db_password" {
  description = "RDS master password. Supply via terraform.tfvars or TF_VAR_db_password."
  type        = string
  sensitive   = true
}

variable "db_multi_az" {
  description = "Multi-AZ RDS. Set false to reduce cost while testing."
  type        = bool
  default     = false
}
