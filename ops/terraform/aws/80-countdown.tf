module "remote_termination" {
  source         = "./modules/remote_termination"
  
  count          = local.countdown == null ? 0 : 1

  suffix         = "${split("@", local.config.email)[0]}-${local.config.region}"
  function_name  = local.config.name
  instance_id    = aws_instance.ec2_instance.id
  eip_id         = aws_eip.eip.id
  sender_email   = local.config.existing_data.ses_sender
  sender_region  = local.config.existing_data.region
  receiver_email = local.config.email

  depends_on     = [aws_instance.ec2_instance]
  
  tags           = {
    Name = local.config.name
  }
}

