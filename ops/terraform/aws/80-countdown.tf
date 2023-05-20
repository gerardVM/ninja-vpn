module "remote_termination" {
  source        = "./modules/remote_termination"
  
  count         = local.countdown == null ? 0 : 1

  function_name = local.config.name
  instance_id   = aws_instance.ec2_instance.id
  eip_id        = aws_eip.eip.id
  email         = local.config.email

  depends_on    = [aws_instance.ec2_instance]
  
  tags        = {
    Name = local.config.name
  }
}

