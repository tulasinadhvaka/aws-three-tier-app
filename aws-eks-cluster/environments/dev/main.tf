terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "aws-eks-cluster"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "eks" {
  source             = "../../modules/eks-cluster"
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  subnet_ids         = var.private_subnet_ids
}

# General-purpose on-demand group — steady workloads.
module "node_group_general" {
  source          = "../../modules/eks-node-group"
  cluster_name    = module.eks.cluster_name
  node_group_name = "general"
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["t3.medium"]
  capacity_type   = "ON_DEMAND"
  desired_size    = 2
  min_size        = 1
  max_size        = 4
  labels          = { nodegroup = "general", workload = "general" }
}

# Spot group — cost-optimised, fault-tolerant workloads. Multiple types = better Spot availability.
module "node_group_spot" {
  source          = "../../modules/eks-node-group"
  cluster_name    = module.eks.cluster_name
  node_group_name = "spot"
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["t3.medium", "t3a.medium", "t3.large"]
  capacity_type   = "SPOT"
  desired_size    = 1
  min_size        = 0
  max_size        = 5
  labels          = { nodegroup = "spot", workload = "batch" }
}

# System group — tainted so only tolerating pods land here. Optional.
module "node_group_system" {
  count           = var.enable_system_group ? 1 : 0
  source          = "../../modules/eks-node-group"
  cluster_name    = module.eks.cluster_name
  node_group_name = "system"
  subnet_ids      = var.private_subnet_ids
  instance_types  = ["t3.medium"]
  capacity_type   = "ON_DEMAND"
  desired_size    = 1
  min_size        = 1
  max_size        = 2
  labels          = { nodegroup = "system" }
  taints = [{
    key    = "dedicated"
    value  = "system"
    effect = "NO_SCHEDULE"
  }]
}
