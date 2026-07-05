output "state_bucket_name" {
  description = "S3 bucket that holds remote state for the other stacks"
  value       = aws_s3_bucket.state.id
}

output "lock_table_name" {
  description = "DynamoDB table used for state locking"
  value       = aws_dynamodb_table.lock.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "ci_plan_role_arn" {
  description = "ARN of the read-only CI role used for terraform plan"
  value       = aws_iam_role.ci_plan.arn
}

output "ci_apply_role_arn" {
  description = "ARN of the CI role used for terraform apply on main"
  value       = aws_iam_role.ci_apply.arn
}
