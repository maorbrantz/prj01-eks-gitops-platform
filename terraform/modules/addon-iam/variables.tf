variable "cluster_name" {
  description = "Name of the EKS cluster the pod identity associations target"
  type        = string
}

variable "route53_zone_id" {
  description = "Hosted zone id external-dns is allowed to change records in"
  type        = string
}

variable "secret_name_prefix" {
  description = "Secrets Manager name prefix external-secrets is allowed to read"
  type        = string
  default     = "prj01"
}

variable "tags" {
  description = "Extra tags applied to the IAM roles"
  type        = map(string)
  default     = {}
}
