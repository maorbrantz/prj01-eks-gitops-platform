terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name = var.name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true

  # One NAT gateway for the whole VPC instead of one per AZ. This halves the
  # hourly NAT cost, which matters for an ephemeral dev cluster that is torn
  # down after each session. The trade-off (a single-AZ failure taking out
  # egress for private nodes) is spelled out in docs/adr/002-single-nat-gateway.md.
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Public subnets host internet-facing load balancers. Private subnets host
  # nodes and internal load balancers. These tags let the AWS Load Balancer
  # Controller pick the right subnets automatically.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = var.cluster_name
  }

  tags = var.tags
}
