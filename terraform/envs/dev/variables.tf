variable "region" {
  description = "AWS region for the dev environment"
  type        = string
  default     = "il-central-1"
}

variable "profile" {
  description = "Named AWS profile used for authentication"
  type        = string
  default     = "prj01"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "prj01-dev"
}

variable "cluster_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.33"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["il-central-1a", "il-central-1b", "il-central-1c"]
}

variable "admin_access_role_arns" {
  description = "IAM role ARNs granted cluster admin via EKS access entries"
  type        = list(string)
}
