terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

# the zone was created and delegated by hand, terraform only reads it so a plan
# can never change the NS set and break the GoDaddy delegation.
data "aws_route53_zone" "this" {
  zone_id = var.route53_zone_id
}

# certificate for the app hostname. dns validation records are written below.
resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

# the CNAME records ACM needs to prove domain ownership. these live in the zone
# already, but the GoDaddy NS delegation for prj1.maorbrantz.com is not live yet,
# so ACM cannot see them publicly and the certificate stays PENDING_VALIDATION.
# that is expected for now. there is deliberately no aws_acm_certificate_validation
# resource here: a validation waiter would block apply until the cert issues, which
# cannot happen until delegation is confirmed. the HTTPS listener flip and the
# waiter come in a later phase.
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.this.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 300
  allow_overwrite = true
}
