variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes control-plane version."
  type        = string
  default     = "1.30"
}

variable "subnet_ids" {
  description = "Subnets for the control plane ENIs and node groups (private, >= 2 AZs)."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Whether the API server is reachable from the public internet."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
