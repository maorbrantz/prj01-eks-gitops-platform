variable "cluster_name" {
  description = "Name of the EKS cluster Karpenter runs against"
  type        = string
}

variable "tags" {
  description = "Extra tags applied to all Karpenter resources"
  type        = map(string)
  default     = {}
}
