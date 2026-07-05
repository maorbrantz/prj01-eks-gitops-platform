variable "name" {
  description = "Name prefix for the VPC and its subnets"
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR blocks for the private subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
}

variable "public_subnets" {
  description = "CIDR blocks for the public subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.96.0/22", "10.0.100.0/22", "10.0.104.0/22"]
}

variable "cluster_name" {
  description = "EKS cluster name, used for subnet discovery tags"
  type        = string
}

variable "tags" {
  description = "Extra tags applied to all network resources"
  type        = map(string)
  default     = {}
}
