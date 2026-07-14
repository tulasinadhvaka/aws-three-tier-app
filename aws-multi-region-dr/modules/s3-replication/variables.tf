variable "name_prefix" {
  description = "Name prefix. No hardcoded names."
  type        = string
}

variable "bucket_suffix" {
  description = "Unique suffix to keep bucket names globally unique (e.g. account id)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
