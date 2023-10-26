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

# resource "aws_route53_record" "all_subdomains" {
#   name   = "*.${local.domain_name}"
#   type   = "CNAME"
#   zone_id = aws_route53_zone.hosted_zone.zone_id
#   alias {
#     name                   = aws_cloudfront_distribution.distribution.domain_name
#     zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

resource "aws_route53_record" "root_domain" {
  name   = local.domain_name
  type   = "A"
  zone_id = aws_route53_zone.hosted_zone.zone_id
  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# output "cloudfront_domain_name" {
#   value = aws_route53_record.root_domain.name
# }
