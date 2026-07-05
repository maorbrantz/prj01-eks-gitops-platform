output "node_iam_role_name" {
  description = "Name of the IAM role Karpenter-launched nodes assume"
  value       = module.karpenter.node_iam_role_name
}

output "node_iam_role_arn" {
  description = "ARN of the IAM role Karpenter-launched nodes assume"
  value       = module.karpenter.node_iam_role_arn
}

output "queue_name" {
  description = "Name of the SQS interruption queue"
  value       = module.karpenter.queue_name
}

output "iam_role_arn" {
  description = "ARN of the Karpenter controller IAM role used by the Pod Identity association"
  value       = module.karpenter.iam_role_arn
}

output "iam_role_name" {
  description = "Name of the Karpenter controller IAM role"
  value       = module.karpenter.iam_role_name
}
