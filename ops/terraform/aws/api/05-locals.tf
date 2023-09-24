locals {
    config        = yamldecode(file("${path.root}/../../../../config.yaml"))
    api_region    = local.config.region
    api_accountId = local.config.account

    tags          = {
        Name = "vpn-lambda-controller"
    }
}