locals {
    config      = yamldecode(file("${path.root}/../../../config.yaml"))
    countdown   = try(local.config.countdown, null)
    private_key = file("${path.root}/../../.ssh/id_rsa")
    public_key  = file("${path.root}/../../.ssh/id_rsa.pub")
}

resource "aws_launch_template" "launch_template" {
  name_prefix   = local.config.name
  image_id      = local.config.image_id

  instance_market_options {
    market_type = "spot"
  }

  instance_type = local.config.instance_type

  key_name      = aws_key_pair.ssh_keys.key_name

  monitoring {
    enabled = false
  }  
  
  # network_interfaces {
  #   associate_public_ip_address = true
  #   delete_on_termination       = true
  #   device_index                = 0
  #   # subnet_id                   = module.vpc.public_subnets[0]
  # }

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
    public_key  = local.public_key
}

resource "aws_instance" "ec2_instance" {
  
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  provisioner "file" {
    source      = "./files/docker-compose.yaml"
    destination = "/home/ec2-user/docker-compose.yaml"

    connection {
       type = "ssh"
       user = "ec2-user"
       private_key = local.private_key
       host = self.public_ip
    }
  }

  provisioner "file" {
    source      = "./files/install-vpn.sh"
    destination = "/home/ec2-user/install-vpn.sh"

    connection {
       type = "ssh"
       user = "ec2-user"
       private_key = local.private_key
       host = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/install-vpn.sh",
      "export TIMEZONE=${local.config.my_timezone}",
      "export ADDRESS=${self.public_dns}",
      "/home/ec2-user/install-vpn.sh",
    ]

    connection {
       type = "ssh"
       user = "ec2-user"
       private_key = local.private_key
       host = self.public_ip
    }
  }
  
  tags = {
    Name = local.config.name
  }
}