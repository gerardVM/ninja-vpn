resource "aws_s3_bucket" "bucket" {
    bucket = local.config.bucket_name
}