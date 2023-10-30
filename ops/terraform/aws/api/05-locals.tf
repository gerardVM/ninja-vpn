locals {
    config        = yamldecode(file("${path.root}/../../../../config.yaml"))
    index_path    = "${path.root}/../../../../site/frontend/index_template.html"
    api_region    = local.config.api_region
    api_accountId = local.config.account
    domain_name   = local.config.domain
    g_recaptcha   = "6LeXIdwoAAAAAFdV2OnJ18CPHT8Z59aK9mi0CrYp"

    tags          = {
        Name = "vpn-lambda-controller"
    }
}