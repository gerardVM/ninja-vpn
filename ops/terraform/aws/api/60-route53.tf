resource "aws_route53_zone" "hosted_zone" {
  name = local.domain_name
}

resource "aws_route53_record" "validation" {
  for_each = { for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
    name    = dvo.resource_record_name
    value   = dvo.resource_record_value
    type    = dvo.resource_record_type
    zone_id = aws_route53_zone.hosted_zone.zone_id
  } }
  name    = each.value.name
  type    = each.value.type
  zone_id = each.value.zone_id
  records = [each.value.value]
  ttl     = 60
  }
