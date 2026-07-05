# prj01-eks-gitops-platform

[![ci](https://github.com/maorbrantz/prj01-eks-gitops-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/maorbrantz/prj01-eks-gitops-platform/actions/workflows/ci.yml)
[![apply](https://github.com/maorbrantz/prj01-eks-gitops-platform/actions/workflows/apply.yml/badge.svg)](https://github.com/maorbrantz/prj01-eks-gitops-platform/actions/workflows/apply.yml)

Production style Kubernetes platform on AWS. Terraform provisions the infrastructure (VPC, EKS, Karpenter, IAM), ArgoCD manages everything running in the cluster from this repo.

Work in progress. Application code lives in [prj01-linkpulse-app](https://github.com/maorbrantz/prj01-linkpulse-app).
