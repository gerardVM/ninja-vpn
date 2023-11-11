resource "aws_sesv2_email_identity" "email_notifications" {
    email_identity = aws_route53_zone.hosted_zone.name

    dkim_signing_attributes {
        next_signing_key_length = "RSA_2048_BIT"
    }
}