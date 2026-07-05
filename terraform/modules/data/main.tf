terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

# links table: one row per short code. the api writes it on create and reads it
# on redirect, keyed only by short_code.
resource "aws_dynamodb_table" "links" {
  name         = "prj01-links"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_code"

  attribute {
    name = "short_code"
    type = "S"
  }

  tags = var.tags
}

# click-stats table: the worker aggregates clicks per (short_code, day) and the
# api queries all days for a short_code. hash short_code, range day matches the
# worker StatsRepository.increment key and the api StatsRepository.by_short_code
# query.
resource "aws_dynamodb_table" "click_stats" {
  name         = "prj01-click-stats"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_code"
  range_key    = "day"

  attribute {
    name = "short_code"
    type = "S"
  }

  attribute {
    name = "day"
    type = "S"
  }

  tags = var.tags
}

# dead letter queue for click events the worker cannot process. maxReceiveCount 5
# on the main queue moves a poison message here after five failed receives.
resource "aws_sqs_queue" "clicks_dlq" {
  name                      = "prj01-clicks-dlq"
  message_retention_seconds = 1209600

  tags = var.tags
}

# main click queue. the api sends one message per redirect, the worker long polls
# (20s) and batch deletes after writing to dynamodb. visibility timeout is 60s,
# comfortably above the worker's poll plus fast dynamodb increment so an in flight
# batch is not redelivered.
resource "aws_sqs_queue" "clicks" {
  name                       = "prj01-clicks"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.clicks_dlq.arn
    maxReceiveCount     = 5
  })

  tags = var.tags
}

locals {
  ecr_repos = [
    "prj01/linkpulse-api",
    "prj01/linkpulse-worker",
    "prj01/linkpulse-web",
  ]
}

resource "aws_ecr_repository" "linkpulse" {
  for_each = toset(local.ecr_repos)

  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

# keep the last 10 images per repo so the registry does not grow without bound.
resource "aws_ecr_lifecycle_policy" "linkpulse" {
  for_each = aws_ecr_repository.linkpulse

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
