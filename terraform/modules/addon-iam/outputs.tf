output "alb_controller_role_arn" {
  description = "IAM role ARN bound to the aws-load-balancer-controller service account"
  value       = module.aws_load_balancer_controller.iam_role_arn
}

output "external_dns_role_arn" {
  description = "IAM role ARN bound to the external-dns service account"
  value       = module.external_dns.iam_role_arn
}

output "external_secrets_role_arn" {
  description = "IAM role ARN bound to the external-secrets service account"
  value       = module.external_secrets.iam_role_arn
}
