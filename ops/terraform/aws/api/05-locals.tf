locals {
    config      = yamldecode(file("${path.root}/../../../../config.yaml"))
    index_path  = "${path.root}/../../../../site/frontend/index_template.html"

    bucket_name = local.config.bucket_name
    domain_name = local.config.domain

    tags          = {
        Name = "vpn-lambda-controller"
    }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}