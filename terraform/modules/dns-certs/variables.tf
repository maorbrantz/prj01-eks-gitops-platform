variable "route53_zone_id" {
  description = "Hosted zone id the certificate validation records are written into"
  type        = string
}

variable "domain_name" {
  description = "Fully qualified domain name the certificate is issued for"
  type        = string
}

variable "tags" {
  description = "Extra tags applied to the certificate"
  type        = map(string)
  default     = {}
}
