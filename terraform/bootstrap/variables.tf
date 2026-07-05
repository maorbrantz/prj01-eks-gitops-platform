variable "region" {
  description = "AWS region for all bootstrap resources"
  type        = string
  default     = "il-central-1"
}

variable "profile" {
  description = "Named AWS profile used for authentication"
  type        = string
  default     = "prj01"
}

variable "account_id" {
  description = "AWS account id the bootstrap runs against"
  type        = string
  default     = "149536464688"
}

variable "github_org" {
  description = "GitHub organisation or user that owns the platform repo"
  type        = string
  default     = "maorbrantz"
}

variable "github_repo" {
  description = "GitHub repository that CI roles trust"
  type        = string
  default     = "prj01-eks-gitops-platform"
}

variable "app_github_repo" {
  description = "GitHub repository for the linkpulse app that the ECR push role trusts"
  type        = string
  default     = "prj01-linkpulse-app"
}

variable "linkpulse_ecr_repos" {
  description = "ECR repository names the app CI role may push to"
  type        = list(string)
  default = [
    "prj01/linkpulse-api",
    "prj01/linkpulse-worker",
    "prj01/linkpulse-web",
  ]
}
