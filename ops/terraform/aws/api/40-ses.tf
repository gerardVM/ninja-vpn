resource "aws_sesv2_email_identity" "email_notifications" {
    email_identity = local.config.ses_sender_email
}