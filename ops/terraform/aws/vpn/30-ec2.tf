data "template_file" "user_data" {
  template = file("${path.root}/files/user_data.sh")

  vars = {
    NAME                = "${local.config.name}-${replace(split("@", local.config.email)[0], ".", "-")}-${local.config.region}"
    EIP_ID              = aws_eip.eip.id
    CURRENT_REGION      = local.config.region
    SERVERURL           = aws_eip.eip.public_dns
    TIMEZONE            = local.config.timezone
    DOCKER_CONFIG       = "/root/.docker"
    S3_BUCKET           = data.aws_s3_bucket.bucket.bucket
    S3_DC_KEY           = aws_s3_object.docker-compose.key
    S3_CE_KEY           = aws_s3_object.config_email.key
    S3_TH_KEY           = aws_s3_object.termination_handler.key
    S3_IV_KEY           = aws_s3_object.install_vpn.key
    S3_SE_KEY           = aws_s3_object.send_email.key
    S3_CD_KEY           = aws_s3_object.countdown.key
    S3_WC_KEY           = "${local.config.region}/${local.config.email}/wireguard_config"
    SENDER_EMAIL        = local.config.ses_sender_email
    RECEIVER_EMAIL      = local.config.email # aws_sesv2_email_identity.email_notifications.email_identity if your account is in the Amazon SES sandbox
    SES_REGION          = local.config.api_region
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

  user_data = base64encode(data.template_file.user_data.rendered)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name      = local.config.name
    }
  }
}

resource "aws_spot_fleet_request" "spot_fleet_request" {
  iam_fleet_role = aws_iam_role.fleet_role.arn

  launch_template_config {
    launch_template_specification {
      id      = aws_launch_template.launch_template.id
      version = aws_launch_template.launch_template.latest_version
    }
  }

  spot_maintenance_strategies {
    capacity_rebalance {
      replacement_strategy = "launch"
    }
  }

  target_capacity = 1
  allocation_strategy = "lowestPrice"
  instance_interruption_behaviour = "terminate"
  terminate_instances_on_delete = true
  instance_pools_to_use_count = 1

}

resource "aws_eip" "eip" {
  vpc = true
}

resource "aws_security_group" "security_group" {
  name_prefix = "${local.config.name}-${replace(split("@", local.config.email)[0], ".", "-")}-"
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
