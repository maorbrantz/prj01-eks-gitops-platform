module "network" {
  source = "../../modules/network"

  name         = var.cluster_name
  cidr         = var.vpc_cidr
  azs          = var.azs
  cluster_name = var.cluster_name
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  admin_access_role_arns = var.admin_access_role_arns
}

module "karpenter" {
  source = "../../modules/karpenter"

  cluster_name = module.eks.cluster_name
}

module "addon_iam" {
  source = "../../modules/addon-iam"

  cluster_name    = module.eks.cluster_name
  route53_zone_id = var.route53_zone_id
}

module "data" {
  source = "../../modules/data"

  cluster_name  = module.eks.cluster_name
  app_namespace = var.app_namespace
}

module "dns_certs" {
  source = "../../modules/dns-certs"

  route53_zone_id = var.route53_zone_id
  domain_name     = var.app_domain_name
}

# Karpenter 1.x runs an instance profile garbage collector that calls
# iam:ListInstanceProfiles, which the controller policy the karpenter module
# ships does not grant. Without it the controller logs a 403 on a loop. This
# supplements the module role rather than forking the module policy.
resource "aws_iam_role_policy" "karpenter_list_instance_profiles" {
  name = "list-instance-profiles"
  role = module.karpenter.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListInstanceProfiles"
        Effect   = "Allow"
        Action   = "iam:ListInstanceProfiles"
        Resource = "*"
      }
    ]
  })
}
