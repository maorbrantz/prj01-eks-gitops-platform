terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile

  default_tags {
    tags = {
      Project   = "prj01"
      ManagedBy = "terraform"
      Repo      = "prj01-eks-gitops-platform"
      Env       = "dev"
    }
  }
}
