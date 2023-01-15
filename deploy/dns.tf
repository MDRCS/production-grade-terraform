data "aws_route53_zone" "zone" {
  name = "${var.dns_zone_name}."
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${lookup(var.subdomain, terraform.workspace)}.${data.aws_route53_zone.zone.name}" # example : api.dev.django-rest-api.com
  type    = "CNAME"
  ttl     = "300"

  records = [aws_lb.api.dns_name] # link dns to the load balancer url
}

# Adding HTTPS certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = aws_route53_record.app.fqdn # domain name defined for each environment
  validation_method = "DNS"

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  # better than accessing cases with indexes
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  ttl     = "60"
  type    = each.value.type
  zone_id = data.aws_route53_zone.zone.zone_id

}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn] # because we used for_each in the previous component we should continue with the same paradigm
}
