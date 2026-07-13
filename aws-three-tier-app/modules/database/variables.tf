variable "name" {
  description = "Name prefix for database resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the DB security group in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the DB subnet group (>= 2 AZs)."
  type        = list(string)
}

variable "app_security_group_id" {
  description = "App security group — DB only accepts traffic from this."
  type        = string
}

variable "db_port" {
  description = "Database port."
  type        = number
  default     = 3306
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password. Supply via tfvars or TF_VAR_db_password; never commit."
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "multi_az" {
  description = "Enable Multi-AZ for high availability (costs more)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
