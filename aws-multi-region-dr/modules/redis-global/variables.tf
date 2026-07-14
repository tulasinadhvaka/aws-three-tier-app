variable "name_prefix" {
  description = "Name prefix. No hardcoded names."
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type (must support Global Datastore)."
  type        = string
  default     = "cache.r6g.large"
}

variable "engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "primary_subnet_ids" {
  description = "Subnet IDs in the PRIMARY region."
  type        = list(string)
}

variable "dr_subnet_ids" {
  description = "Subnet IDs in the DR region."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
