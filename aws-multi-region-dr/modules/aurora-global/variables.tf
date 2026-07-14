variable "name_prefix" {
  description = "Name prefix. No hardcoded names."
  type        = string
}

variable "engine" {
  description = "Aurora engine (aurora-postgresql or aurora-mysql)."
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "Aurora engine version supporting Global Database."
  type        = string
  default     = "15.4"
}

variable "instance_class" {
  description = "DB instance class."
  type        = string
  default     = "db.r6g.large"
}

variable "master_username" {
  description = "Master username."
  type        = string
  default     = "dbadmin"
}

variable "master_password" {
  description = "Master password. Supply via TF_VAR / tfvars; never commit."
  type        = string
  sensitive   = true
}

variable "primary_subnet_ids" {
  description = "Private subnet IDs in the PRIMARY region."
  type        = list(string)
}

variable "dr_subnet_ids" {
  description = "Private subnet IDs in the DR region."
  type        = list(string)
}

variable "primary_vpc_id" {
  description = "VPC ID in the primary region (for the DB security group)."
  type        = string
}

variable "dr_vpc_id" {
  description = "VPC ID in the DR region (for the DB security group)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
