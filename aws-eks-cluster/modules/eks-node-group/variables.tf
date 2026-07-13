variable "cluster_name" {
  description = "Name of the EKS cluster this node group joins."
  type        = string
}

variable "node_group_name" {
  description = "Name of this node group."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the nodes (>= 2 AZs)."
  type        = list(string)
}

variable "instance_types" {
  description = "Instance types for the node group. Multiple types recommended for Spot."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "desired_size" {
  description = "Desired number of nodes."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of nodes."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes."
  type        = number
  default     = 3
}

variable "disk_size" {
  description = "Node root volume size (GiB)."
  type        = number
  default     = 20
}

variable "labels" {
  description = "Kubernetes labels applied to nodes."
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "Kubernetes taints (key/value/effect) applied to nodes."
  type = list(object({
    key    = string
    value  = string
    effect = string # NO_SCHEDULE | PREFER_NO_SCHEDULE | NO_EXECUTE
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
