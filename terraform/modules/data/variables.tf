variable "cluster_name" {
  description = "EKS cluster the pod identity associations target"
  type        = string
}

variable "app_namespace" {
  description = "Kubernetes namespace the LinkPulse service accounts live in"
  type        = string
  default     = "linkpulse-dev"
}

variable "tags" {
  description = "Extra tags applied to the resources"
  type        = map(string)
  default     = {}
}
