# Uncomment if your account is in the Amazon SES sandbox

# resource "aws_sesv2_email_identity" "email_notifications" {
#     email_identity = "${replace(split("@", local.config.email)[0], ".", "-")}+${local.config.region}@${split("@", local.config.email)[1]}"

#     provider = aws.shared-infra
# }