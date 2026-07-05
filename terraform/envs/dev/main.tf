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
