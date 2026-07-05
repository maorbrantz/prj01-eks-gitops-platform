data "aws_region" "current" {}

# pod identity roles for the two app service accounts. same pattern as the
# platform addon roles: the association binds an iam role to a
# (namespace, service account) pair, the pod-identity-agent injects credentials,
# no irsa annotations needed. the chart must name the service accounts to match.

# api: creates links and reads them back, sends a click event per redirect.
module "api_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12"

  name = "prj01-linkpulse-api"

  attach_custom_policy = true
  policy_statements = [
    {
      sid = "LinksAndStatsReadWrite"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
      ]
      resources = [
        aws_dynamodb_table.links.arn,
        aws_dynamodb_table.click_stats.arn,
      ]
    },
    {
      sid       = "PublishClicks"
      actions   = ["sqs:SendMessage", "sqs:GetQueueUrl", "sqs:GetQueueAttributes"]
      resources = [aws_sqs_queue.clicks.arn]
    }
  ]

  associations = {
    main = {
      cluster_name    = var.cluster_name
      namespace       = var.app_namespace
      service_account = "linkpulse-api"
    }
  }

  tags = var.tags
}

# worker: consumes click events and writes aggregated counts, reads links only if
# it needs to resolve a code.
module "worker_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12"

  name = "prj01-linkpulse-worker"

  attach_custom_policy = true
  policy_statements = [
    {
      sid = "ConsumeClicks"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:DeleteMessageBatch",
        "sqs:GetQueueUrl",
        "sqs:GetQueueAttributes",
      ]
      resources = [aws_sqs_queue.clicks.arn]
    },
    {
      sid = "WriteStats"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query",
        "dynamodb:BatchWriteItem",
      ]
      resources = [aws_dynamodb_table.click_stats.arn]
    },
    {
      sid       = "ReadLinks"
      actions   = ["dynamodb:GetItem", "dynamodb:Query"]
      resources = [aws_dynamodb_table.links.arn]
    }
  ]

  associations = {
    main = {
      cluster_name    = var.cluster_name
      namespace       = var.app_namespace
      service_account = "linkpulse-worker"
    }
  }

  tags = var.tags
}
