locals {
  repo_sub = "repo:${var.github_org}/${var.github_repo}"
}

# --- prj01-ci-plan -----------------------------------------------------------
# Used by the ci workflow to run terraform plan on pull requests. Trust is open
# to any branch and to pull_request events of this repo, but the permissions are
# read-only plus just enough state access to hold the lock and read/write the
# plan-time state objects.

data "aws_iam_policy_document" "ci_plan_trust" {
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
      values   = ["${local.repo_sub}:*"]
    }
  }
}

resource "aws_iam_role" "ci_plan" {
  name               = "prj01-ci-plan"
  description        = "GitHub Actions role for terraform plan (read-only plus state access)"
  assume_role_policy = data.aws_iam_policy_document.ci_plan_trust.json

  tags = {
    Name = "prj01-ci-plan"
    Role = "ci-plan"
  }
}

resource "aws_iam_role_policy_attachment" "ci_plan_readonly" {
  role       = aws_iam_role.ci_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "ci_plan_state" {
  statement {
    sid       = "StateBucketList"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    sid       = "StateObjectReadWrite"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }

  statement {
    sid    = "LockTableAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [aws_dynamodb_table.lock.arn]
  }
}

resource "aws_iam_role_policy" "ci_plan_state" {
  name   = "prj01-ci-plan-state"
  role   = aws_iam_role.ci_plan.id
  policy = data.aws_iam_policy_document.ci_plan_state.json
}

# --- prj01-ci-apply ----------------------------------------------------------
# Used by the apply workflow. Trust is restricted to the main branch of this
# repo only, so a pull request from a fork or a feature branch can never assume
# it. In a real account this role would carry a scoped permission boundary; here
# it uses AdministratorAccess because the platform provisions VPC, EKS and IAM
# across the whole account and this is a throwaway sandbox.

data "aws_iam_policy_document" "ci_apply_trust" {
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
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.repo_sub}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "ci_apply" {
  name               = "prj01-ci-apply"
  description        = "GitHub Actions role for terraform apply (main branch only)"
  assume_role_policy = data.aws_iam_policy_document.ci_apply_trust.json

  tags = {
    Name = "prj01-ci-apply"
    Role = "ci-apply"
  }
}

# Sandbox choice: broad access so the platform stacks can manage VPC, EKS, IAM,
# and data resources. Production would attach a permission boundary here instead.
resource "aws_iam_role_policy_attachment" "ci_apply_admin" {
  role       = aws_iam_role.ci_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
