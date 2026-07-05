output "links_table_name" {
  description = "Name of the links DynamoDB table"
  value       = aws_dynamodb_table.links.name
}

output "links_table_arn" {
  description = "ARN of the links DynamoDB table"
  value       = aws_dynamodb_table.links.arn
}

output "click_stats_table_name" {
  description = "Name of the click-stats DynamoDB table"
  value       = aws_dynamodb_table.click_stats.name
}

output "click_stats_table_arn" {
  description = "ARN of the click-stats DynamoDB table"
  value       = aws_dynamodb_table.click_stats.arn
}

output "clicks_queue_url" {
  description = "URL of the click events SQS queue"
  value       = aws_sqs_queue.clicks.url
}

output "clicks_queue_arn" {
  description = "ARN of the click events SQS queue"
  value       = aws_sqs_queue.clicks.arn
}

output "clicks_dlq_url" {
  description = "URL of the click events dead letter queue"
  value       = aws_sqs_queue.clicks_dlq.url
}

output "ecr_repository_urls" {
  description = "Map of ECR repository name to repository URL"
  value       = { for name, repo in aws_ecr_repository.linkpulse : name => repo.repository_url }
}

output "api_role_arn" {
  description = "IAM role ARN bound to the linkpulse-api service account"
  value       = module.api_pod_identity.iam_role_arn
}

output "worker_role_arn" {
  description = "IAM role ARN bound to the linkpulse-worker service account"
  value       = module.worker_pod_identity.iam_role_arn
}
