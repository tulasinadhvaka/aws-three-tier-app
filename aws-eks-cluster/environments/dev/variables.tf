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

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "dev-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the cluster and nodes (>= 2 AZs)."
  type        = list(string)
}

variable "enable_system_group" {
  description = "Create the tainted system node group (extra cost). Off by default."
  type        = bool
  default     = false
}
