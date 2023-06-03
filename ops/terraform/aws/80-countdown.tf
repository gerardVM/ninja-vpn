module "remote_termination" {
  source         = "./modules/remote_termination"
  
  count          = local.countdown == null ? 0 : 1

  suffix         = "${split("@", local.config.email)[0]}-${local.config.region}"
  function_name  = local.config.name
  instance_id    = aws_instance.ec2_instance.id
  eip_id         = aws_eip.eip.id
  sender_email   = local.config.existing_data.ses_sender
  receiver_email = aws_sesv2_email_identity.email_notifications.email_identity
  ses_region     = local.config.existing_data.region

  depends_on     = [aws_instance.ec2_instance]
  
  tags           = {
    Name = local.config.name
  }
}

