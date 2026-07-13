variable "name" {
  description = "Name prefix for IAM resources (usually the environment name)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
