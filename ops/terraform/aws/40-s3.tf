resource "aws_s3_bucket" "bucket" {
  bucket = "ninja-vpn-bucket"
}

resource "aws_s3_object" "docker-compose" {
  bucket = "${aws_s3_bucket.bucket.id}"
  key    = "docker-compose.yaml"
  source = "files/docker-compose.yaml"
}

resource "aws_s3_object" "config_email" {
  bucket = "${aws_s3_bucket.bucket.id}"
  key    = "config_email.txt"
  source = "files/config_email.txt"
}