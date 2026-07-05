variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.33"
}

variable "vpc_id" {
  description = "VPC the cluster runs in"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the control plane ENIs and node group"
  type        = list(string)
}

variable "system_node_group" {
  description = "Sizing for the system managed node group"
  type = object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    capacity_type  = string
  })
  default = {
    instance_types = ["t3.medium"]
    min_size       = 2
    max_size       = 4
    desired_size   = 4
    capacity_type  = "ON_DEMAND"
  }
}

variable "admin_access_role_arns" {
  description = "IAM role ARNs granted cluster admin via EKS access entries"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Extra tags applied to all cluster resources"
  type        = map(string)
  default     = {}
}
