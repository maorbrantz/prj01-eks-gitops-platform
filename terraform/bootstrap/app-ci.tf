locals {
  app_repo_sub  = "repo:${var.github_org}/${var.app_github_repo}"
  ecr_repo_arns = [for name in var.linkpulse_ecr_repos : "arn:aws:ecr:${var.region}:${var.account_id}:repository/${name}"]
}

# --- prj01-app-ci ------------------------------------------------------------
# Used by the release workflow in the app repo to push images to ECR. Trust is
# scoped to the app repo, and permissions cover only the linkpulse ECR repos
# plus the account-wide GetAuthorizationToken that any docker login needs.

data "aws_iam_policy_document" "app_ci_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.app_repo_sub}:*"]
    }
  }
}

resource "aws_iam_role" "app_ci" {
  name               = "prj01-app-ci"
  description        = "GitHub Actions role for the linkpulse app repo (ECR push only)"
  assume_role_policy = data.aws_iam_policy_document.app_ci_trust.json

  tags = {
    Name = "prj01-app-ci"
    Role = "app-ci"
  }
}

data "aws_iam_policy_document" "app_ci_ecr" {
  statement {
    sid       = "EcrAuthToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = local.ecr_repo_arns
  }
}

resource "aws_iam_role_policy" "app_ci_ecr" {
  name   = "prj01-app-ci-ecr"
  role   = aws_iam_role.app_ci.id
  policy = data.aws_iam_policy_document.app_ci_ecr.json
}
