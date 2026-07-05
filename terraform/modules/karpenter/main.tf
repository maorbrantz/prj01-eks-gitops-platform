terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

# Controller prerequisites only. This creates the node IAM role, the Pod
# Identity association for the Karpenter controller, and the SQS interruption
# queue with its EventBridge rules. The Helm install of the controller and the
# NodePool / EC2NodeClass manifests come in later phases, not here.
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.37"

  cluster_name = var.cluster_name

  # Use Pod Identity rather than IRSA for the controller. It needs no OIDC
  # trust wiring and is the direction EKS is moving.
  enable_pod_identity             = true
  create_pod_identity_association = true

  # Let the module create the interruption SQS queue and the EventBridge rules
  # that feed it spot interruption and rebalance notices.
  enable_spot_termination = true

  # The node role needs the SSM managed policy so nodes can register and be
  # managed. This is the standard set for Karpenter-launched nodes.
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = var.tags
}
