variable "name_prefix" {
  description = "Name prefix (e.g. <env>-<role>). No hardcoded names."
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR."
  type        = string
}

variable "az_count" {
  description = "Number of AZs to spread subnets across."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
