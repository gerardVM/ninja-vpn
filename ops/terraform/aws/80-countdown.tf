module "countdown" {
  source      = "./modules/countdown"
  
  count       = local.countdown == null ? 0 : 1

  instance_id = aws_instance.ec2_instance.id
  eip_id      = aws_eip.eip.id
  email       = local.config.email
  countdown   = local.countdown

  depends_on  = [aws_instance.ec2_instance]
  
  tags        = {
    Name = local.config.name
  }
}

