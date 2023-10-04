resource "aws_acm_certificate" "cert" {
  domain_name       = local.domain_name
  validation_method = "DNS"

  tags = {
    Environment = "staging"
  }

  lifecycle {
    create_before_destroy = true
  }
}
