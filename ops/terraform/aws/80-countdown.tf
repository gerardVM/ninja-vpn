module "remote_termination" {
  source         = "./modules/remote_termination"
  
  count          = local.countdown == null ? 0 : 1

  suffix         = "${replace(split("@", local.config.email)[0], ".", "-")}-${local.config.region}"
  function_name  = local.config.name
  eip_id         = aws_eip.eip.id
  sender_email   = local.config.existing_data.ses_sender
  receiver_email = local.config.email # aws_sesv2_email_identity.email_notifications.email_identity if your account is in the Amazon SES sandbox
  ses_region     = local.config.existing_data.region
  
  tags           = {
    Name = local.config.name
  }
}

