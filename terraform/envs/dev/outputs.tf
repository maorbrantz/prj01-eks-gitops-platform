output "vpc_id" {
  description = "ID of the dev VPC"
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (nodes and internal load balancers)"
  value       = module.network.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs (internet-facing load balancers)"
  value       = module.network.public_subnet_ids
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS Kubernetes API"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded CA certificate for the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster"
  value       = module.eks.cluster_version
}

output "karpenter_node_iam_role_name" {
  description = "IAM role name for Karpenter-launched nodes"
  value       = module.karpenter.node_iam_role_name
}

output "karpenter_queue_name" {
  description = "SQS interruption queue name for Karpenter"
  value       = module.karpenter.queue_name
}

output "alb_controller_role_arn" {
  description = "IAM role ARN for the aws-load-balancer-controller pod identity"
  value       = module.addon_iam.alb_controller_role_arn
}

output "external_dns_role_arn" {
  description = "IAM role ARN for the external-dns pod identity"
  value       = module.addon_iam.external_dns_role_arn
}

output "external_secrets_role_arn" {
  description = "IAM role ARN for the external-secrets pod identity"
  value       = module.addon_iam.external_secrets_role_arn
}

output "update_kubeconfig_command" {
  description = "Ready to run command that writes a kubeconfig entry for this cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region} --profile ${var.profile}"
}
