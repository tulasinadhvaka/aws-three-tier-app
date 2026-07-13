output "cluster_name" {
  description = "Run: aws eks update-kubeconfig --name <this> --region <region>"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  description = "For wiring IRSA roles (LB controller, autoscaler, etc.)."
  value       = module.eks.oidc_provider_arn
}

output "node_groups" {
  description = "Node groups created."
  value = compact([
    module.node_group_general.node_group_name,
    module.node_group_spot.node_group_name,
    var.enable_system_group ? module.node_group_system[0].node_group_name : "",
  ])
}
