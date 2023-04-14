resource "aws_s3_bucket" "bucket" {
  bucket = "ninja-vpn-bucket"
}

resource "aws_s3_bucket_object" "docker-compose" {
  bucket = "${aws_s3_bucket.bucket.id}"
  key    = "docker-compose.yaml"
  source = "files/docker-compose.yaml"
}

resource "aws_s3_bucket_object" "build-email" {
  bucket = "${aws_s3_bucket.bucket.id}"
  key    = "build-email.sh"
  source = "files/build-email.sh"
}