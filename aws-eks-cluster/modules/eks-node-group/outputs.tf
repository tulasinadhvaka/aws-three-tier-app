output "node_group_name" {
  description = "Name of the managed node group."
  value       = aws_eks_node_group.this.node_group_name
}

output "node_role_arn" {
  description = "IAM role ARN used by the nodes."
  value       = aws_iam_role.node.arn
}

output "node_group_status" {
  description = "Current status of the node group."
  value       = aws_eks_node_group.this.status
}
