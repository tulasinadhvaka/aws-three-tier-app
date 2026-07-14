variable "primary_region" {
  description = "Primary AWS region."
  type        = string
  default     = "us-east-1"
}

variable "dr_region" {
  description = "DR AWS region."
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (part of the name prefix)."
  type        = string
  default     = "dev"
}

variable "primary_cidr" {
  description = "Primary VPC CIDR."
  type        = string
  default     = "10.10.0.0/16"
}

variable "dr_cidr" {
  description = "DR VPC CIDR."
  type        = string
  default     = "10.20.0.0/16"
}

variable "db_master_password" {
  description = "Aurora master password. Supply via TF_VAR_db_master_password."
  type        = string
  sensitive   = true
}

variable "bucket_suffix" {
  description = "Globally-unique suffix for S3 bucket names (e.g. account id)."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 hosted zone id for failover records."
  type        = string
}

variable "record_name" {
  description = "DNS record for the app (e.g. app.example.com)."
  type        = string
}

variable "notification_email" {
  description = "Email for DR alerts (optional)."
  type        = string
  default     = ""
}
