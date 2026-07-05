terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Public endpoint is on so I can reach the API from my workstation without a
  # bastion or VPN. This is a disposable dev cluster; for prod I would make the
  # endpoint private and restrict public CIDRs. Nodes still live in private
  # subnets and talk to the API over the private path.
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Core addons. Versions are resolved by the module to the latest compatible
  # build for the chosen cluster version. eks-pod-identity-agent backs the
  # Pod Identity associations used by Karpenter and later platform addons.
  cluster_addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = {}
    eks-pod-identity-agent = {}
  }

  eks_managed_node_groups = {
    system = {
      instance_types = var.system_node_group.instance_types
      capacity_type  = var.system_node_group.capacity_type

      min_size     = var.system_node_group.min_size
      max_size     = var.system_node_group.max_size
      desired_size = var.system_node_group.desired_size

      labels = {
        "role" = "system"
      }
    }
  }

  # API-based access management. The role that runs terraform apply keeps admin
  # so it can manage the cluster, and each ARN passed in (the SSO admin role for
  # console/kubectl access and the CI apply role) gets cluster admin too.
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    for arn in var.admin_access_role_arns : arn => {
      principal_arn = arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # Karpenter discovers the cluster security group by this tag when it launches
  # nodes, so the nodes land in the right SG.
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  tags = var.tags
}
