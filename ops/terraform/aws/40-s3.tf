data "aws_s3_bucket" "bucket" {
  bucket = local.config.existing_data.bucket
  
  provider = aws.shared-infra
}

resource "aws_s3_object" "docker-compose" {
  bucket = data.aws_s3_bucket.bucket.id
  key    = "${local.config.region}/${local.config.email}/docker-compose.yaml"
  source = "files/docker-compose.yaml"
  
  provider = aws.shared-infra

}

resource "aws_s3_object" "config_email" {
  bucket = data.aws_s3_bucket.bucket.id
  key    = "${local.config.region}/${local.config.email}/config_email.txt"
  source = "files/config_email.txt"
  
  provider = aws.shared-infra
}

resource "aws_s3_object" "termination_script" {
  bucket = data.aws_s3_bucket.bucket.id
  key    = "${local.config.region}/${local.config.email}/termination_script.sh"
  source = "files/termination_script.sh"
  
  provider = aws.shared-infra
}