variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "cidr_block" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.2.0.0/16"
}

variable "azs" {
  description = "Availability zones."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (one per AZ)."
  type        = list(string)
  default     = ["10.2.0.0/24", "10.2.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (one per AZ)."
  type        = list(string)
  default     = ["10.2.10.0/24", "10.2.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT Gateway. Enabled in prod."
  type        = bool
  default     = true
}
