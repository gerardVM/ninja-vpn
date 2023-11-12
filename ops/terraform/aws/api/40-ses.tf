locals {
    dkim_tokens = flatten([
    for attribute in aws_sesv2_email_identity.email_notifications.dkim_signing_attributes : [
        for token in attribute.tokens : token
    ]
    ])
}

resource "aws_sesv2_email_identity" "email_notifications" {
    email_identity = aws_route53_zone.hosted_zone.name

    dkim_signing_attributes {
        next_signing_key_length = "RSA_2048_BIT"
    }
}

resource "aws_route53_record" "email_verification" {
  for_each = { for token in local.dkim_tokens : token => token }

  name   = "${each.value}._domainkey.${aws_route53_record.root_domain.name}"
  type   = "CNAME"
  zone_id = aws_route53_zone.hosted_zone.zone_id
  ttl     = 300
  records = ["${each.value}.dkim.amazonses.com"]
}
