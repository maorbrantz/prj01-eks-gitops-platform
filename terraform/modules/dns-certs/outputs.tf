output "certificate_arn" {
  description = "ARN of the ACM certificate (stays PENDING_VALIDATION until NS delegation is live)"
  value       = aws_acm_certificate.this.arn
}

output "domain_name" {
  description = "Domain name the certificate covers"
  value       = aws_acm_certificate.this.domain_name
}
