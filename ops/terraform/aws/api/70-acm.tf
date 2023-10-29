resource "aws_acm_certificate" "cert" {
  domain_name               = aws_route53_zone.hosted_zone.name
  subject_alternative_names = ["*.${aws_route53_zone.hosted_zone.name}"]
  validation_method         = "DNS"

  tags = {
    Environment = "staging"
  }

  lifecycle {
    create_before_destroy = true
  }

  provider = aws.us_east_1
}
