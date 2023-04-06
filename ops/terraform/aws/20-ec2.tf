locals {
    config    = yamldecode(file("${path.root}/../../../config.yaml"))
    countdown = try(local.config.countdown, null)
}

resource "aws_launch_template" "launch_template" {
  name = local.config.name

  image_id = local.config.image_id

  instance_market_options {
    market_type = "spot"
  }

  instance_type = local.config.instance_type

  key_name      = aws_key_pair.ssh_keys.key_name

  monitoring {
    enabled = false
  }

  vpc_security_group_ids = [aws_security_group.security_group.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = local.config.name
    }
  }
}

resource "aws_key_pair" "ssh_keys" {
    key_name    = local.config.name
    public_key  = file("${path.root}/../../.ssh/id_rsa.pub")
}

resource "aws_security_group" "security_group" {
  name_prefix = "${local.config.name}-"
  description = "Allow SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.config.name
  }

}

resource "aws_instance" "ec2_instance" {
  
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  tags = {
    Name = local.config.name
  }

  depends_on = [
    aws_launch_template.launch_template,
    aws_key_pair.ssh_keys,
    aws_security_group.security_group
  ]

}

module "countdown" {
  source      = "./modules/countdown"
  
  count       = local.countdown == null ? 0 : 1

  instance_id = aws_instance.ec2_instance.id
  countdown   = local.countdown

  depends_on  = [aws_instance.ec2_instance]
  
  tags        = {
    Name = local.config.name
  }
}

output public_dns {
  value = aws_instance.ec2_instance.public_dns
}