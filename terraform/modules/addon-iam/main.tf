terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM role plus Pod Identity association for each platform addon that touches
# AWS. Pod Identity is used everywhere here: the association binds the role to a
# (namespace, service account) pair and the pod-identity-agent injects
# credentials, so no OIDC trust wiring or IRSA annotations are needed. The charts
# in gitops/platform must use the matching service account names.

# aws-load-balancer-controller: uses the official upstream policy verbatim,
# stored alongside this module and refreshed when the chart is bumped.
module "aws_load_balancer_controller" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12"

  name = "prj01-alb-controller"

  attach_custom_policy    = true
  source_policy_documents = [file("${path.module}/policies/aws-load-balancer-controller.json")]

  associations = {
    main = {
      cluster_name    = var.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = var.tags
}

# external-dns: scoped to the one hosted zone it manages, plus the account-wide
# list calls it needs to discover that zone.
module "external_dns" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12"

  name = "prj01-external-dns"

  attach_custom_policy = true
  policy_statements = [
    {
      sid       = "ChangeRecords"
      actions   = ["route53:ChangeResourceRecordSets"]
      resources = ["arn:aws:route53:::hostedzone/${var.route53_zone_id}"]
    },
    {
      sid       = "ListRecords"
      actions   = ["route53:ListResourceRecordSets", "route53:ListTagsForResources"]
      resources = ["arn:aws:route53:::hostedzone/${var.route53_zone_id}"]
    },
    {
      sid       = "DiscoverZones"
      actions   = ["route53:ListHostedZones"]
      resources = ["*"]
    }
  ]

  associations = {
    main = {
      cluster_name    = var.cluster_name
      namespace       = "external-dns"
      service_account = "external-dns"
    }
  }

  tags = var.tags
}

# external-secrets: read only, scoped to secrets under the prj01/ name prefix.
module "external_secrets" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.12"

  name = "prj01-external-secrets"

  attach_custom_policy = true
  policy_statements = [
    {
      sid = "ReadPrj01Secrets"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.secret_name_prefix}/*"]
    },
    {
      sid       = "ListSecrets"
      actions   = ["secretsmanager:ListSecrets"]
      resources = ["*"]
    }
  ]

  associations = {
    main = {
      cluster_name    = var.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
    }
  }

  tags = var.tags
}
