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

output "links_table_name" {
  description = "Name of the links DynamoDB table"
  value       = module.data.links_table_name
}

output "click_stats_table_name" {
  description = "Name of the click-stats DynamoDB table"
  value       = module.data.click_stats_table_name
}

output "clicks_queue_url" {
  description = "URL of the click events SQS queue"
  value       = module.data.clicks_queue_url
}

output "clicks_dlq_url" {
  description = "URL of the click events dead letter queue"
  value       = module.data.clicks_dlq_url
}

output "ecr_repository_urls" {
  description = "Map of ECR repository name to repository URL"
  value       = module.data.ecr_repository_urls
}

output "linkpulse_api_role_arn" {
  description = "IAM role ARN for the linkpulse-api pod identity"
  value       = module.data.api_role_arn
}

output "linkpulse_worker_role_arn" {
  description = "IAM role ARN for the linkpulse-worker pod identity"
  value       = module.data.worker_role_arn
}

output "linkpulse_certificate_arn" {
  description = "ARN of the LinkPulse ACM certificate"
  value       = module.dns_certs.certificate_arn
}

output "update_kubeconfig_command" {
  description = "Ready to run command that writes a kubeconfig entry for this cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region} --profile ${var.profile}"
}
