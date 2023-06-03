data "template_file" "install_vpn" {
  template = file("${path.module}/files/install-vpn.sh")

  vars = {
    NAME                = "${local.config.name}-${split("@", local.config.email)[0]}-${local.config.region}"
    CURRENT_REGION      = local.config.region
    SERVERURL           = aws_eip.eip.public_dns
    TIMEZONE            = local.config.timezone
    DOCKER_CONFIG       = "/root/.docker"
    S3_BUCKET           = data.aws_s3_bucket.bucket.bucket
    S3_DC_KEY           = aws_s3_object.docker-compose.key
    S3_CE_KEY           = aws_s3_object.config_email.key
    SENDER_EMAIL        = local.config.existing_data.ses_sender
    RECEIVER_EMAIL      = aws_sesv2_email_identity.email_notifications.email_identity
    SES_REGION          = local.config.existing_data.region
    COUNTDOWN           = try(local.config.countdown, "0")
  }
}

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${local.config.image}*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_launch_template" "launch_template" {

  iam_instance_profile {
    name = aws_iam_instance_profile.profile.name
  }

  name_prefix   = local.config.name
  image_id      = data.aws_ami.ami.id

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
  name_prefix = "${local.config.name}-${split("@", local.config.email)[0]}-"
  description = "Allow VPN traffic"

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