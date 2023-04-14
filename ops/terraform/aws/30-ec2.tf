data "template_file" "install_vpn" {
  template = file("${path.module}/files/install-vpn.sh")

  vars = {
    SERVERURL     = aws_eip.eip.public_dns
    TIMEZONE      = local.config.my_timezone
    DOCKER_CONFIG = "/root/.docker"
    S3_BUCKET     = aws_s3_bucket.bucket.bucket
    S3_DC_KEY     = aws_s3_bucket_object.docker-compose.key
    S3_BE_KEY     = aws_s3_bucket_object.build-email.key
    EMAIL_ADDRESS = local.config.email
  }
}

resource "aws_launch_template" "launch_template" {

  iam_instance_profile {
    name = aws_iam_instance_profile.profile.name
  }

  name_prefix   = local.config.name
  image_id      = local.config.image_id

  instance_market_options {
    market_type = "spot"
  }

  instance_type = local.config.instance_type

  monitoring {
    enabled = false
  }  

  vpc_security_group_ids = [aws_security_group.security_group.id]

  user_data = base64encode(data.template_file.install_vpn.rendered)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name      = local.config.name
    }
  }
}

resource "aws_instance" "ec2_instance" {
  
  launch_template {
    id              = aws_launch_template.launch_template.id
    version         = "$Latest"
  }
  
  tags = {
    Name            = local.config.name
  }
}

resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_eip_association" "eip_assoc" {
  allocation_id = aws_eip.eip.id
  instance_id   = aws_instance.ec2_instance.id
}

resource "aws_security_group" "security_group" {
  name_prefix = "${local.config.name}-"
  description = "Allow SSH traffic"

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