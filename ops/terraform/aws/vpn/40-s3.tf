data "aws_s3_bucket" "bucket" {
  bucket = local.config.bucket_name
  
  provider = aws.api_infra
}

resource "aws_s3_object" "install_vpn" {
  bucket = data.aws_s3_bucket.bucket.id
  key    = "${local.config.region}/${local.config.email}/install-vpn.sh"
  source = "files/scripts/install-vpn.sh"
  
  provider = aws.api_infra
}

resource "aws_s3_object" "docker-compose" {
  bucket = data.aws_s3_bucket.bucket.id
  key    = "${local.config.region}/${local.config.email}/docker-compose.yaml"
  source = "files/docker-compose.yaml"
  
  provider = aws.api_infra

}

resource "aws_s3_object" "termination_handler" {
  bucket = data.aws_s3_bucket.bucket.id
  key    = "${local.config.region}/${local.config.email}/termination_handler.sh"
  source = "files/scripts/termination_handler.sh"
  
  provider = aws.api_infra
}

resource "aws_s3_object" "send_email" {
  bucket = data.aws_s3_bucket.bucket.id
  key    = "${local.config.region}/${local.config.email}/send-email.sh"
  source = "files/scripts/send-email.sh"
  
  provider = aws.api_infra
}

resource "aws_s3_object" "config_email" {
  bucket = data.aws_s3_bucket.bucket.id
  key    = "${local.config.region}/${local.config.email}/config_email.txt"
  source = "files/config_email.txt"
  
  provider = aws.api_infra
}