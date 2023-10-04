locals {
    config        = yamldecode(file("${path.root}/../../../../config.yaml"))
    index_path    = "${path.module}/../../../../site/frontend/index_template.html"
    api_region    = local.config.api_region
    api_accountId = local.config.account

    tags          = {
        Name = "vpn-lambda-controller"
    }
}